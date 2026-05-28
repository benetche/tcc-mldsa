#!/usr/bin/env bash
# Deploy no Raspberry Pi via rsync + SSH — sem git no Pi.
# Requer: ssh, rsync; senha em lab.env (SSH_ASKPASS) ou chave SSH.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PI_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_ROOT="$(cd "${PI_ROOT}/../.." && pwd)"

LAB_ENV="${PI_ROOT}/lab.env"
if [[ ! -f "${LAB_ENV}" ]]; then
  echo "ERRO: crie ${LAB_ENV} a partir de lab.env.example" >&2
  exit 1
fi
# shellcheck disable=SC1090
source "${LAB_ENV}"

PI_HOST="${PI_HOST:?PI_HOST obrigatório em lab.env}"
PI_USER="${PI_USER:?PI_USER obrigatório em lab.env}"
PI_REMOTE_SUBDIR="${PI_REMOTE_SUBDIR:-tcc-iomt}"
FABRIC_VERSION="${FABRIC_VERSION:-2.5.12}"

FABRIC_SAMPLES_LOCAL="${FABRIC_SAMPLES_DIR:-${REPO_ROOT}/fabric-samples}"
TN_LOCAL="${FABRIC_SAMPLES_LOCAL}/test-network"

if [[ ! -d "${TN_LOCAL}/organizations" ]]; then
  echo "ERRO: organizations não encontrado em ${TN_LOCAL}" >&2
  echo "Suba a rede no PC: fabric/baseline/scripts/network-up.sh" >&2
  exit 1
fi

if [[ -z "${LAB_FABRIC_HOST:-}" ]]; then
  LAB_FABRIC_HOST="$(hostname -I 2>/dev/null | awk '{print $1}')"
  if [[ -z "${LAB_FABRIC_HOST}" ]]; then
    echo "ERRO: defina LAB_FABRIC_HOST em lab.env" >&2
    exit 1
  fi
  echo "LAB_FABRIC_HOST auto-detectado: ${LAB_FABRIC_HOST}"
fi

SSH_OPTS=(-o StrictHostKeyChecking=accept-new -o ConnectTimeout=10)
SSH_WRAPPER=()
RSYNC_RSH=""

setup_ssh_auth() {
  if [[ -n "${PI_SSH_KEY:-}" ]]; then
    SSH_OPTS+=(-i "${PI_SSH_KEY}")
    return 0
  fi
  if [[ -n "${PI_SSH_PASSWORD:-}" ]] && command -v sshpass &>/dev/null; then
    export SSHPASS="${PI_SSH_PASSWORD}"
    SSH_WRAPPER=(sshpass -e)
    RSYNC_RSH="sshpass -e ssh ${SSH_OPTS[*]}"
    return 0
  fi
  if [[ -n "${PI_SSH_PASSWORD:-}" ]]; then
    ASKPASS_SCRIPT="$(mktemp)"
    printf '#!/bin/sh\necho %s\n' "${PI_SSH_PASSWORD}" > "${ASKPASS_SCRIPT}"
    chmod 700 "${ASKPASS_SCRIPT}"
    export SSH_ASKPASS="${ASKPASS_SCRIPT}"
    export SSH_ASKPASS_REQUIRE=force
    export DISPLAY="${DISPLAY:-:0}"
    SSH_WRAPPER=(setsid)
    RSYNC_RSH="setsid ssh ${SSH_OPTS[*]}"
    trap 'rm -f "${ASKPASS_SCRIPT}"' EXIT
    return 0
  fi
  RSYNC_RSH="ssh ${SSH_OPTS[*]}"
}

setup_ssh_auth

run_ssh() {
  "${SSH_WRAPPER[@]}" ssh "${SSH_OPTS[@]}" "${PI_USER}@${PI_HOST}" "$@"
}

run_rsync() {
  local src="$1" dest="$2"
  shift 2
  rsync -az "$@" -e "${RSYNC_RSH}" "${src}" "${PI_USER}@${PI_HOST}:${dest}"
}

echo "==> Testando SSH ${PI_USER}@${PI_HOST}..."
REMOTE_BASE="$(run_ssh "echo \"\${HOME}/${PI_REMOTE_SUBDIR}\"")"
echo "    Diretório remoto: ${REMOTE_BASE}"

run_ssh "mkdir -p \"${REMOTE_BASE}/edge/raspberry-pi\" \"${REMOTE_BASE}/fabric-samples/test-network\" \"${REMOTE_BASE}/fabric-samples/config\" \"${REMOTE_BASE}/fabric-samples/bin\""

echo "==> Configurando /etc/hosts no Pi (TLS Fabric → ${LAB_FABRIC_HOST})..."
HOSTS_LINE="${LAB_FABRIC_HOST} peer0.org1.example.com peer0.org2.example.com orderer.example.com"
PI_SUDO_PASS="${PI_SUDO_PASSWORD:-${PI_SSH_PASSWORD:-}}"
if ! run_ssh "bash -s" <<REMOTE
set -uo pipefail
LINE="${HOSTS_LINE}"
if grep -q 'peer0.org1.example.com' /etc/hosts 2>/dev/null; then
  echo "hosts Fabric já configurado"
  exit 0
fi
if [[ -n "${PI_SUDO_PASS}" ]]; then
  echo '${PI_SUDO_PASS}' | sudo -S sh -c "echo \"\${LINE}\" >> /etc/hosts"
  echo "Adicionado em /etc/hosts: \${LINE}"
  exit 0
fi
echo "sudo indisponível sem senha" >&2
exit 1
REMOTE
then
  echo "AVISO: não foi possível editar /etc/hosts no Pi." >&2
  echo "Adicione manualmente no Pi (sudo nano /etc/hosts):" >&2
  echo "  ${HOSTS_LINE}" >&2
fi

echo "==> Cross-compilando submit-observation (linux/arm64)..."
mkdir -p "${PI_ROOT}/bin"
(
  cd "${PI_ROOT}"
  GOOS=linux GOARCH=arm64 CGO_ENABLED=0 go build -o "${PI_ROOT}/bin/submit-observation" ./cmd/submit-observation/
)

echo "==> Sincronizando cliente edge/raspberry-pi..."
run_rsync "${PI_ROOT}/" "${REMOTE_BASE}/edge/raspberry-pi/" \
  --exclude lab.env --exclude '.git'

echo "==> Sincronizando credenciais Fabric (peer + orderer TLS, sem fabric-ca)..."
run_ssh "mkdir -p \"${REMOTE_BASE}/fabric-samples/test-network/organizations/peerOrganizations\" \
  \"${REMOTE_BASE}/fabric-samples/test-network/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts\""
run_rsync "${TN_LOCAL}/organizations/peerOrganizations/" \
  "${REMOTE_BASE}/fabric-samples/test-network/organizations/peerOrganizations/"
run_rsync "${TN_LOCAL}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/" \
  "${REMOTE_BASE}/fabric-samples/test-network/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/"

echo "==> Sincronizando config Fabric..."
run_rsync "${FABRIC_SAMPLES_LOCAL}/config/" \
  "${REMOTE_BASE}/fabric-samples/config/"

echo "==> Instalando binário peer (ARM64) no Pi, se necessário..."
run_ssh "bash -s" <<REMOTE
set -euo pipefail
REMOTE_DIR="${REMOTE_BASE}"
FABRIC_VER="${FABRIC_VERSION}"
BIN="\${REMOTE_DIR}/fabric-samples/bin/peer"
if [[ -x "\${BIN}" ]]; then
  echo "peer já presente: \$(\${BIN} version 2>/dev/null | head -1 || true)"
  exit 0
fi
ARCH=\$(uname -m)
case "\${ARCH}" in
  aarch64|arm64) FABRIC_ARCH=arm64 ;;
  armv7l|armv6l) FABRIC_ARCH=arm ;;
  x86_64|amd64) FABRIC_ARCH=amd64 ;;
  *) echo "Arquitetura não suportada: \${ARCH}"; exit 1 ;;
esac
TMP=\$(mktemp -d)
URL="https://github.com/hyperledger/fabric/releases/download/v\${FABRIC_VER}/hyperledger-fabric-linux-\${FABRIC_ARCH}-\${FABRIC_VER}.tar.gz"
echo "Baixando \${URL}..."
curl -fsSL "\${URL}" | tar -xz -C "\${TMP}"
mkdir -p "\${REMOTE_DIR}/fabric-samples/bin"
cp "\${TMP}/bin/peer" "\${REMOTE_DIR}/fabric-samples/bin/"
chmod +x "\${REMOTE_DIR}/fabric-samples/bin/peer"
rm -rf "\${TMP}"
echo "peer instalado: \$(\${BIN} version | head -1)"
REMOTE

echo "==> Gravando config.env no Pi..."
run_ssh "bash -s" <<REMOTE
cat > "${REMOTE_BASE}/edge/raspberry-pi/config.env" <<EOF
export REPO_ROOT=${REMOTE_BASE}
export FABRIC_SAMPLES_DIR=${REMOTE_BASE}/fabric-samples
export PATH=${REMOTE_BASE}/fabric-samples/bin:\${PATH}
export FABRIC_MSP_ID=Org1MSP
export FABRIC_MSP_DIR=${REMOTE_BASE}/fabric-samples/test-network/organizations/peerOrganizations/org1.example.com/users/User1@org1.example.com/msp
export FABRIC_CHANNEL=${FABRIC_CHANNEL:-iomtchannel}
export FABRIC_CHAINCODE=${FABRIC_CHAINCODE:-iomt}
export FABRIC_PEER_ENDPOINT=${LAB_FABRIC_HOST}:7051
export IOMT_DEVICE_ID=${IOMT_DEVICE_ID:-pi-lab-001}
export IOMT_SUBMIT_MODE=peer-cli
EOF
REMOTE

echo "==> Smoke test C1 no Pi..."
run_ssh "bash -lc 'cd \"${REMOTE_BASE}/edge/raspberry-pi\" && source config.env && ./scripts/smoke-c1.sh'"

echo ""
echo "OK: deploy em ${PI_USER}@${PI_HOST}:${REMOTE_BASE}"
echo "    Fabric peer: ${LAB_FABRIC_HOST}:7051"
