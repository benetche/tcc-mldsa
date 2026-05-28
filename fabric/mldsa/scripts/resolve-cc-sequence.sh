#!/usr/bin/env bash
# Define CC_SEQUENCE: auto (próxima livre) ou número fixo.
set -eo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

require_fabric_samples
TN="$(test_network_dir)"
export PATH="${FABRIC_SAMPLES_DIR}/bin:${PATH}"
export FABRIC_CFG_PATH="${TN}/../config/"

export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID=Org1MSP
export CORE_PEER_TLS_ROOTCERT_FILE="${TN}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt"
export CORE_PEER_MSPCONFIGPATH="${TN}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp"
export CORE_PEER_ADDRESS=localhost:7051

if [[ -n "${CC_SEQUENCE:-}" && "${CC_SEQUENCE}" != "auto" ]]; then
  echo "${CC_SEQUENCE}"
  exit 0
fi

if ! peer lifecycle chaincode querycommitted \
  --channelID "${CHANNEL_NAME}" \
  --name "${CHAINCODE_NAME}" 2>/dev/null | grep -q "Sequence:"; then
  echo "1"
  exit 0
fi

CURRENT="$(
  peer lifecycle chaincode querycommitted \
    --channelID "${CHANNEL_NAME}" \
    --name "${CHAINCODE_NAME}" 2>/dev/null \
    | sed -n 's/.*Sequence: \([0-9][0-9]*\).*/\1/p' \
    | head -1
)"

if [[ -z "${CURRENT}" ]]; then
  echo "1"
else
  echo "$((CURRENT + 1))"
fi
