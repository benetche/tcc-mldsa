#!/usr/bin/env bash
# Reinicia containers CCAAS com NETWORK_LABEL=mldsa (rótulo no ledger).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

require_fabric_samples
TN="$(test_network_dir)"
export PATH="${FABRIC_SAMPLES_DIR}/bin:${PATH}"
export FABRIC_CFG_PATH="${TN}/../config/"

NETWORK_LABEL="${NETWORK_LABEL:-mldsa}"
CCAAS_PORT="${CCAAS_SERVER_PORT:-9999}"
IMAGE="${CHAINCODE_NAME}_ccaas_image:latest"

PKG_ID="$(cd "${TN}" && peer lifecycle chaincode querycommitted \
  --channelID "${CHANNEL_NAME}" --name "${CHAINCODE_NAME}" 2>/dev/null \
  | awk '/Version:/{v=1} v&&/Sequence:/{print; exit}' || true)"

# Obter package id instalado
PACKAGE_ID="$(docker inspect "peer0org1_${CHAINCODE_NAME}_ccaas" --format '{{range .Config.Env}}{{println .}}{{end}}' 2>/dev/null \
  | grep '^CORE_CHAINCODE_ID_NAME=' | cut -d= -f2- || true)"

if [[ -z "${PACKAGE_ID}" ]]; then
  PACKAGE_ID="$(peer lifecycle chaincode queryinstalled --output json 2>/dev/null \
    | jq -r --arg n "${CHAINCODE_NAME}" '.installed_chaincodes[] | select(.label|contains($n)) | .package_id' | head -1)"
fi

if [[ -z "${PACKAGE_ID}" || "${PACKAGE_ID}" == "null" ]]; then
  echo "ERRO: package id do chaincode não encontrado" >&2
  exit 1
fi

docker rm -f "peer0org1_${CHAINCODE_NAME}_ccaas" "peer0org2_${CHAINCODE_NAME}_ccaas" 2>/dev/null || true

for peer in org1 org2; do
  docker run --rm -d \
    --name "peer0${peer}_${CHAINCODE_NAME}_ccaas" \
    --network fabric_test \
    -e "CHAINCODE_SERVER_ADDRESS=0.0.0.0:${CCAAS_PORT}" \
    -e "CHAINCODE_ID=${PACKAGE_ID}" \
    -e "CORE_CHAINCODE_ID_NAME=${PACKAGE_ID}" \
    -e "NETWORK_LABEL=${NETWORK_LABEL}" \
    "${IMAGE}"
done

echo "[network=mldsa] Aguardando CCAAS (5s)..."
sleep 5
echo "[network=mldsa] CCAAS reiniciado com NETWORK_LABEL=${NETWORK_LABEL} (${PACKAGE_ID})"
