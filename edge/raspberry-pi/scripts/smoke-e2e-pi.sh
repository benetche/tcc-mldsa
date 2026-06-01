#!/usr/bin/env bash
# E2E no Pi: C1 (baseline) + C2 (mldsa) + FHIR opcional.
# Uso no Pi: ./scripts/smoke-e2e-pi.sh
# No PC após deploy: ssh pi 'cd ~/tcc-iomt/edge/raspberry-pi && source config.env && ./scripts/smoke-e2e-pi.sh'
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PI_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_ROOT="${REPO_ROOT:-$(cd "${PI_ROOT}/../.." && pwd)}"

RUN_FHIR="${RUN_FHIR:-1}"

echo "=== C1 (baseline / ECDSA borda) ==="
(
  export FABRIC_NETWORK=baseline
  export IOMT_SCENARIO=C1
  # shellcheck disable=SC1091
  [[ -f "${PI_ROOT}/config.env" ]] && source "${PI_ROOT}/config.env"
  export FABRIC_NETWORK=baseline
  "${SCRIPT_DIR}/smoke-c1.sh"
)

echo ""
echo "=== C2 (mldsa / ML-DSA borda) ==="
(
  export FABRIC_NETWORK=mldsa
  export IOMT_SCENARIO=C2
  # shellcheck disable=SC1091
  [[ -f "${PI_ROOT}/config.env" ]] && source "${PI_ROOT}/config.env"
  export FABRIC_NETWORK=mldsa
  "${SCRIPT_DIR}/smoke-c2.sh"
)

if [[ "${RUN_FHIR}" == "1" ]] && [[ -d "${REPO_ROOT:-}/scripts/ingestion" ]]; then
  echo ""
  echo "=== FHIR (RegisterFhirObservation) ==="
  export FABRIC_NETWORK=baseline
  "${SCRIPT_DIR}/smoke-fhir-pi.sh"
fi

echo ""
echo "OK: smoke E2E Pi (C1 + C2${RUN_FHIR:+ + FHIR})"
