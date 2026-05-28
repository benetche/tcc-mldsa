#!/usr/bin/env bash
# Smoke P3: 3 observações FHIR → chaincode (SYNTHETIC).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
NETWORK="${1:-baseline}"

if [[ -f "${SCRIPT_DIR}/.env" ]]; then
  # shellcheck disable=SC1091
  source "${SCRIPT_DIR}/.env"
fi
export REPO_ROOT="${REPO_ROOT}"
export IOMT_DATA_SOURCE=SYNTHETIC
export FABRIC_NETWORK="${NETWORK}"

cd "${SCRIPT_DIR}"
if [[ -d .venv ]]; then
  # shellcheck disable=SC1091
  source .venv/bin/activate
fi

python3 "${REPO_ROOT}/scripts/ingestion/generate_fixtures.py"
python3 validate_fhir.py
SMOKE_SUFFIX="_smoke_$(date +%s)"
python3 ingest_hospital.py --profile hospital-low --max-records 3 --source SYNTHETIC --id-suffix "${SMOKE_SUFFIX}"

echo "OK: smoke ingestão P3 (${NETWORK})"
