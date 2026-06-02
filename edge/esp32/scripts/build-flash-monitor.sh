#!/usr/bin/env bash
# Build, flash e monitor — requer ESP-IDF no ambiente.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ESP_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PORT="${ESPPORT:-/dev/ttyUSB0}"

if [[ -z "${IDF_PATH:-}" ]] || ! command -v idf.py >/dev/null 2>&1; then
  echo "ESP-IDF não encontrado. Exemplo:"
  echo "  . \$HOME/esp/esp-idf/export.sh"
  exit 1
fi

cd "${ESP_ROOT}"
idf.py set-target esp32 2>/dev/null || true
idf.py -p "${PORT}" build flash monitor
