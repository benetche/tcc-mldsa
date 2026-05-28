#!/usr/bin/env bash
# Smoke test C2: Pi → Fabric ML-DSA → chaincode iomt
# Requer rede fabric/mldsa e binários peer ML-DSA no host Fabric.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PI_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

export IOMT_SUBMIT_MODE="${IOMT_SUBMIT_MODE:-peer-cli}"
export FABRIC_NETWORK="${FABRIC_NETWORK:-mldsa}"

if [[ -f "${PI_ROOT}/config.env" ]]; then
  # shellcheck disable=SC1091
  source "${PI_ROOT}/config.env"
fi

echo "[scenario=C2 network=mldsa] smoke via smoke-c1 (mesmo cliente; rede PQC no host)"
exec "${SCRIPT_DIR}/smoke-c1.sh"
