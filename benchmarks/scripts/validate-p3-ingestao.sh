#!/usr/bin/env bash
# Validação Pilar 3: fixtures FHIR + smoke ingestão (opcional Fabric).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ING="${ROOT}/scripts/ingestion"

echo "[P3] generate + validate FHIR..."
if [[ -d "${ING}/.venv" ]]; then
  # shellcheck disable=SC1091
  source "${ING}/.venv/bin/activate"
fi
pip install -q -r "${ING}/requirements.txt" 2>/dev/null || pip install -q -r "${ING}/requirements.txt"
python3 "${ING}/generate_fixtures.py"
python3 "${ING}/validate_fhir.py"

if [[ -d "${ROOT}/fabric-samples/test-network/organizations" ]]; then
  echo "[P3] smoke ingestão → Fabric..."
  "${ING}/run-ingest-smoke.sh" "${FABRIC_NETWORK:-baseline}"
else
  echo "[P3] skip smoke Fabric (rede ausente)"
fi

echo "OK: Pilar 3 validação concluída"
