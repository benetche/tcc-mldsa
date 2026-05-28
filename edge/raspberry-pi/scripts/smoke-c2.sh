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

echo "[scenario=C2 network=mldsa] smoke Pi → Fabric mldsa"
export FABRIC_NETWORK="${FABRIC_NETWORK:-mldsa}"
cd "${PI_ROOT}"
export REPO_ROOT="${REPO_ROOT:-$(cd "${PI_ROOT}/../.." 2>/dev/null && pwd || echo "")}"
BIN="${PI_ROOT}/bin/submit-observation"
if [[ -x "${BIN}" ]]; then
  exec "${BIN}"
fi
exec "${SCRIPT_DIR}/smoke-c1.sh"
