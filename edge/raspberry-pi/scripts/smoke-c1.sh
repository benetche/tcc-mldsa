#!/usr/bin/env bash
# Smoke test C1: Pi → Fabric baseline → chaincode iomt
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PI_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

if [[ -f "${PI_ROOT}/config.env" ]]; then
  # shellcheck disable=SC1091
  source "${PI_ROOT}/config.env"
fi

cd "${PI_ROOT}"
go run ./cmd/submit-observation/
