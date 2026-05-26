#!/usr/bin/env bash
# Deploy chaincode iomt — CCAAS por padrão (evita docker build dentro do peer).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"${SCRIPT_DIR}/ensure-jq.sh"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

DEPLOY_MODE="${DEPLOY_MODE:-ccaas}"

require_fabric_samples
TN="$(test_network_dir)"
export PATH="${FABRIC_SAMPLES_DIR}/bin:${PATH}"
export FABRIC_CFG_PATH="${TN}/../config/"

CC_SRC="${BASELINE_ROOT}/chaincode/iomt"

echo "[network=baseline] Deploy chaincode ${CHAINCODE_NAME} (modo=${DEPLOY_MODE})..."

cd "${TN}"

if [[ "${DEPLOY_MODE}" == "ccaas" ]]; then
  ./network.sh deployCCAAS \
    -c "${CHANNEL_NAME}" \
    -ccn "${CHAINCODE_NAME}" \
    -ccp "${CC_SRC}" \
    -ccv "${CHAINCODE_VERSION}" \
    -ccs "${CC_SEQUENCE}"
else
  ./network.sh deployCC \
    -c "${CHANNEL_NAME}" \
    -ccn "${CHAINCODE_NAME}" \
    -ccp "${CC_SRC}" \
    -ccl go \
    -ccv "${CHAINCODE_VERSION}" \
    -ccs "${CC_SEQUENCE}"
fi

echo "[network=baseline] Chaincode ${CHAINCODE_NAME} implantado (${DEPLOY_MODE})."
