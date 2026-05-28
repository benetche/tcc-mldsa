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

export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID=Org1MSP
export CORE_PEER_MSPCONFIGPATH="${TN}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp"
export CORE_PEER_TLS_ROOTCERT_FILE="${TN}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt"
export CORE_PEER_ADDRESS=localhost:7051

# Package id alinhado à sequence commitada no canal
COMMITTED_SEQ="$(peer lifecycle chaincode querycommitted --channelID "${CHANNEL_NAME}" --name "${CHAINCODE_NAME}" --output json 2>/dev/null \
  | jq -r '.sequence // empty')"
PACKAGE_ID="$(peer lifecycle chaincode queryinstalled --output json 2>/dev/null \
  | jq -r --arg n "${CHAINCODE_NAME}" --argjson seq "${COMMITTED_SEQ:-0}" \
    '[.installed_chaincodes[] | select(.label|contains($n)) | .package_id] | .[if ($seq|tonumber) > 0 then ($seq|tonumber - 1) else (length - 1) end]')"

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
