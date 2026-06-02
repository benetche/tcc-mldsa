#!/usr/bin/env bash
# Valida hardware + (opcional) build ESP-IDF.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ESP_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PORT="${ESPPORT:-/dev/ttyUSB0}"
DO_BUILD="${DO_BUILD:-0}"

echo "[validate-esp32] detectar porta"
"${SCRIPT_DIR}/detect-esp32.sh"

if ! [[ -r "${PORT}" ]]; then
  echo "[validate-esp32] AVISO: sem leitura em ${PORT} — chip_id pode falhar"
fi

if python3 -m esptool version >/dev/null 2>&1; then
  echo "[validate-esp32] esptool chip_id em ${PORT}"
  python3 -m esptool --port "${PORT}" chip_id || echo "[validate-esp32] chip_id falhou (permissão/cabo?)"
else
  echo "[validate-esp32] instale: python3 -m pip install --user esptool"
fi

if [[ "${DO_BUILD}" == "1" ]] && command -v idf.py >/dev/null 2>&1; then
  echo "[validate-esp32] build (sem flash)"
  cd "${ESP_ROOT}"
  idf.py set-target esp32
  idf.py build
  echo "[validate-esp32] build OK"
elif [[ "${DO_BUILD}" == "1" ]]; then
  echo "[validate-esp32] DO_BUILD=1 mas idf.py ausente"
  exit 1
fi

# Cenários YAML + firmware presente
ROOT="$(cd "${ESP_ROOT}/../.." && pwd)"
"${ROOT}/edge/esp32/scripts/validate-c3-c4-stub.sh" | head -5
test -f "${ESP_ROOT}/main/main.c" && echo "[validate-esp32] firmware main.c presente"

echo "[validate-esp32] concluído"
