#!/usr/bin/env bash
# Smoke FHIR no Pi: 3 observações SYNTHETIC → RegisterFhirObservation (Pilar 3 na borda).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PI_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_ROOT="${REPO_ROOT:-$(cd "${PI_ROOT}/../.." && pwd)}"

if [[ -f "${PI_ROOT}/config.env" ]]; then
  # shellcheck disable=SC1091
  source "${PI_ROOT}/config.env"
fi

export REPO_ROOT="${REPO_ROOT}"
export IOMT_DATA_SOURCE="${IOMT_DATA_SOURCE:-SYNTHETIC}"
export FABRIC_NETWORK="${FABRIC_NETWORK:-baseline}"

ING="${REPO_ROOT}/scripts/ingestion"
if [[ ! -d "${ING}" ]]; then
  echo "ERRO: scripts/ingestion ausente — rode deploy-to-pi.sh com SYNC_FHIR=1" >&2
  exit 1
fi

cd "${ING}"
if [[ ! -d .venv ]]; then
  python3 -m venv .venv
fi
# shellcheck disable=SC1091
source .venv/bin/activate
pip install -q -r requirements.txt

SUFFIX="_pi_fhir_$(date +%s)"
echo "[Pi FHIR smoke] network=${FABRIC_NETWORK} source=${IOMT_DATA_SOURCE}"
python3 ingest_hospital.py --profile hospital-low --max-records 3 --source SYNTHETIC --id-suffix "${SUFFIX}"
echo "OK: smoke FHIR no Pi (RegisterFhirObservation)"
