#!/usr/bin/env bash
# Biblioteca compartilhada — rede Fabric baseline
set -euo pipefail

BASELINE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$(cd "${BASELINE_ROOT}/../.." && pwd)"

if [[ -f "${BASELINE_ROOT}/.env" ]]; then
  # shellcheck disable=SC1091
  source "${BASELINE_ROOT}/.env"
fi

export FABRIC_SAMPLES_DIR="${FABRIC_SAMPLES_DIR:-${REPO_ROOT}/fabric-samples}"
export CHANNEL_NAME="${CHANNEL_NAME:-iomtchannel}"
export CHAINCODE_NAME="${CHAINCODE_NAME:-iomt}"
export CHAINCODE_VERSION="${CHAINCODE_VERSION:-1.0}"
export CC_SEQUENCE="${CC_SEQUENCE:-1}"
export FABRIC_NETWORK="${FABRIC_NETWORK:-baseline}"

test_network_dir() {
  echo "${FABRIC_SAMPLES_DIR}/test-network"
}

require_fabric_samples() {
  local tn
  tn="$(test_network_dir)"
  if [[ ! -d "${tn}" ]]; then
    echo "ERRO: fabric-samples não encontrado em ${FABRIC_SAMPLES_DIR}" >&2
    echo "Execute: ${BASELINE_ROOT}/scripts/bootstrap-samples.sh" >&2
    exit 1
  fi
}
