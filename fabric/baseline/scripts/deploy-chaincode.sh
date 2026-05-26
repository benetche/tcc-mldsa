#!/usr/bin/env bash
# Empacota e faz deploy do chaincode iomt (Go) no canal iomtchannel.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

require_fabric_samples
TN="$(test_network_dir)"
CC_SRC="${BASELINE_ROOT}/chaincode/iomt"
export PATH="${FABRIC_SAMPLES_DIR}/bin:${PATH}"
export FABRIC_CFG_PATH="${TN}/../config/"

cd "${TN}"
echo "[network=baseline] Deploy chaincode ${CHAINCODE_NAME} v${CHAINCODE_VERSION}..."
./network.sh deployCC \
  -ccn "${CHAINCODE_NAME}" \
  -ccp "${CC_SRC}" \
  -ccl go \
  -ccv "${CHAINCODE_VERSION}" \
  -ccs "${CC_SEQUENCE}" \
  -c "${CHANNEL_NAME}"

echo "[network=baseline] Chaincode ${CHAINCODE_NAME} implantado."
