#!/usr/bin/env bash
# Smoke local: submit-observation + verifica signAlg no ledger.
# Uso: validate-local-submit.sh baseline|mldsa
set -euo pipefail
NET="${1:?baseline ou mldsa}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PI_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_ROOT="$(cd "${PI_ROOT}/../.." && pwd)"

export FABRIC_NETWORK="${NET}"
export FABRIC_SAMPLES_DIR="${FABRIC_SAMPLES_DIR:-${REPO_ROOT}/fabric-samples}"
export PATH="${FABRIC_SAMPLES_DIR}/bin:${PATH}"
export REPO_ROOT="${REPO_ROOT}"

case "${NET}" in
  baseline)
    export IOMT_SCENARIO=C1
    export IOMT_EDGE_SIGN=ECDSA-P256
    export FABRIC_PEER_ENDPOINT="${FABRIC_PEER_ENDPOINT:-localhost:7051}"
    ;;
  mldsa)
    export IOMT_SCENARIO=C2
    export IOMT_EDGE_SIGN=ML-DSA-65
    export FABRIC_PEER_ENDPOINT="${FABRIC_PEER_ENDPOINT:-localhost:7051}"
    if ! ls "${REPO_ROOT}/crypto/lib/lib/"liboqs.so* &>/dev/null 2>&1; then
      echo "liboqs ausente — rode crypto/scripts/build-liboqs.sh" >&2
      exit 1
    fi
    export PKG_CONFIG_PATH="${REPO_ROOT}/crypto/lib/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
    export LD_LIBRARY_PATH="${REPO_ROOT}/crypto/lib/lib:${LD_LIBRARY_PATH:-}"
    mkdir -p "${PI_ROOT}/bin"
    if [[ ! -x "${PI_ROOT}/bin/sign-payload-mldsa-host" ]]; then
      (cd "${REPO_ROOT}/crypto" && CGO_ENABLED=1 go build -o "${PI_ROOT}/bin/sign-payload-mldsa-host" ./cmd/sign-payload/)
    fi
    export IOMT_SIGN_PAYLOAD_BIN="${PI_ROOT}/bin/sign-payload-mldsa-host"
    ;;
  *)
    echo "rede desconhecida: ${NET}" >&2
    exit 2
    ;;
esac

cd "${PI_ROOT}"
go build -o /tmp/submit-observation-test ./cmd/submit-observation/
OUT="$(/tmp/submit-observation-test)"
echo "${OUT}"

SIGN_ALG="$(echo "${OUT}" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('ledger',{}).get('signAlg','') if isinstance(d.get('ledger'),dict) else json.loads(d['ledger']).get('signAlg',''))" 2>/dev/null || true)"
if [[ -z "${SIGN_ALG}" ]]; then
  echo "ERRO: signAlg ausente no ledger — redeploy chaincode (deploy-chaincode.sh)" >&2
  exit 1
fi

case "${NET}" in
  baseline)
    [[ "${SIGN_ALG}" == "ECDSA-P256" ]] || { echo "esperado ECDSA-P256, obteve ${SIGN_ALG}"; exit 1; }
    ;;
  mldsa)
    [[ "${SIGN_ALG}" == "ML-DSA-65" ]] || { echo "esperado ML-DSA-65, obteve ${SIGN_ALG}"; exit 1; }
    ;;
esac
echo "OK: assinatura borda ${SIGN_ALG} registrada on-chain"
