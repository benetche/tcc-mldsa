#!/usr/bin/env bash
# Biblioteca compartilhada — rede Fabric ML-DSA (Pilar 2)
set -euo pipefail

MLDSA_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$(cd "${MLDSA_ROOT}/../.." && pwd)"

if [[ -x "${MLDSA_ROOT}/bin/jq" ]]; then
  export PATH="${MLDSA_ROOT}/bin:${PATH}"
fi

if [[ -f "${MLDSA_ROOT}/.env" ]]; then
  # shellcheck disable=SC1091
  source "${MLDSA_ROOT}/.env"
fi

export FABRIC_SAMPLES_DIR="${FABRIC_SAMPLES_DIR:-${REPO_ROOT}/fabric-samples}"
export CHANNEL_NAME="${CHANNEL_NAME:-iomtchannel}"
export CHAINCODE_NAME="${CHAINCODE_NAME:-iomt}"
export CHAINCODE_VERSION="${CHAINCODE_VERSION:-1.0}"
export CC_SEQUENCE="${CC_SEQUENCE:-auto}"
export FABRIC_NETWORK="${FABRIC_NETWORK:-mldsa}"

# Binários Fabric com BCCSP ML-DSA (após build-fabric-mldsa.sh)
if [[ -d "${MLDSA_ROOT}/bin" ]]; then
  export PATH="${MLDSA_ROOT}/bin:${PATH}"
fi

export LIBOQS_PREFIX="${LIBOQS_PREFIX:-${REPO_ROOT}/crypto/lib}"
export LD_LIBRARY_PATH="${LIBOQS_PREFIX}/lib:${LD_LIBRARY_PATH:-}"
export PKG_CONFIG_PATH="${LIBOQS_PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH:-}"

test_network_dir() {
  echo "${FABRIC_SAMPLES_DIR}/test-network"
}

require_fabric_samples() {
  local tn
  tn="$(test_network_dir)"
  if [[ ! -d "${tn}" ]]; then
    echo "ERRO: fabric-samples não encontrado em ${FABRIC_SAMPLES_DIR}" >&2
    echo "Execute: ${MLDSA_ROOT}/scripts/bootstrap-samples.sh" >&2
    exit 1
  fi
}

require_mldsa_bins() {
  if [[ ! -x "${MLDSA_ROOT}/bin/peer" ]]; then
    echo "AVISO: peer ML-DSA não encontrado em ${MLDSA_ROOT}/bin" >&2
    echo "Execute: ${REPO_ROOT}/crypto/scripts/build-fabric-mldsa.sh" >&2
    echo "Rede subirá com binários stock até custom build (baseline crypto)." >&2
  fi
}
