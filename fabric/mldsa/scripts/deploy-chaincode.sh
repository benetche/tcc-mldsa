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

CC_SRC="${MLDSA_ROOT}/chaincode/iomt"

# Sequence automática se já existir definição commitada (evita erro "must be sequence 2")
export CC_SEQUENCE="$("${SCRIPT_DIR}/resolve-cc-sequence.sh")"

echo "[network=mldsa] Deploy chaincode ${CHAINCODE_NAME} (modo=${DEPLOY_MODE}, sequence=${CC_SEQUENCE})..."

# Containers CCAAS da execução anterior (mesmo nome) impedem novo start
if [[ "${DEPLOY_MODE}" == "ccaas" ]]; then
  docker rm -f "peer0org1_${CHAINCODE_NAME}_ccaas" "peer0org2_${CHAINCODE_NAME}_ccaas" 2>/dev/null || true
fi

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

echo "[network=mldsa] Chaincode ${CHAINCODE_NAME} implantado (${DEPLOY_MODE})."
