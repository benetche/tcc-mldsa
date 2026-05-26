#!/usr/bin/env bash
# Verifica containers do test-network e peers respondendo.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

ok=0
if ! docker info &>/dev/null; then
  echo "FAIL: Docker não está acessível"
  exit 1
fi

for c in peer0.org1.example.com peer0.org2.example.com orderer.example.com; do
  if docker ps --format '{{.Names}}' | grep -q "^${c}$"; then
    echo "OK: container ${c}"
  else
    echo "WARN: container ${c} não está rodando"
    ok=1
  fi
done

if [[ "${ok}" -ne 0 ]]; then
  echo "Execute: fabric/baseline/scripts/network-up.sh"
  exit 1
fi

echo "[network=baseline] Health check passou."
