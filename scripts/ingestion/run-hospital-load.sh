#!/usr/bin/env bash
# Carga hospitalar configurável (hospital-low | hospital-high).
set -euo pipefail
PROFILE="${1:-hospital-low}"
NETWORK="${2:-baseline}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

if [[ -f "${SCRIPT_DIR}/.env" ]]; then
  # shellcheck disable=SC1091
  source "${SCRIPT_DIR}/.env"
fi
export REPO_ROOT="${REPO_ROOT}"
export FABRIC_NETWORK="${NETWORK}"
export IOMT_DATA_SOURCE="${IOMT_DATA_SOURCE:-SYNTHETIC}"

cd "${SCRIPT_DIR}"
if [[ -d .venv ]]; then
  # shellcheck disable=SC1091
  source .venv/bin/activate
fi

python3 ingest_hospital.py --profile "${PROFILE}" --source "${IOMT_DATA_SOURCE}"
