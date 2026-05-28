#!/usr/bin/env bash
# Smoke test C1: Pi → Fabric baseline → chaincode iomt
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PI_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

if [[ -f "${PI_ROOT}/config.env" ]]; then
  # shellcheck disable=SC1091
  source "${PI_ROOT}/config.env"
elif [[ -f "${SCRIPT_DIR}/export-fabric-env.sh" ]]; then
  # shellcheck disable=SC1091
  source "${SCRIPT_DIR}/export-fabric-env.sh"
fi

cd "${PI_ROOT}"
export REPO_ROOT="${REPO_ROOT:-$(cd "${PI_ROOT}/../.." && pwd)}"

BIN="${PI_ROOT}/bin/submit-observation"
if [[ -x "${BIN}" ]]; then
  exec "${BIN}"
fi

if ! command -v go >/dev/null 2>&1; then
  echo "ERRO: Go não instalado e bin/submit-observation ausente." >&2
  echo "Execute deploy-to-pi.sh no PC (cross-compile) ou: sudo apt install golang-go" >&2
  exit 1
fi

go run ./cmd/submit-observation/
