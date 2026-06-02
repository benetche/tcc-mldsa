#!/usr/bin/env bash
# Build firmware para C3/C4 e preset hospital-low/high (sem menuconfig manual).
#
# Uso:
#   ./build-scenario.sh C3 low
#   ./build-scenario.sh C4 high
#   FLASH=1 ESPPORT=/dev/ttyUSB0 ./build-scenario.sh C3 low
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ESP_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

SCENARIO="${1:?C3 ou C4}"
LOAD="${2:-low}"

# shellcheck disable=SC1091
source "${SCRIPT_DIR}/setup-idf-env.sh"
cd "${ESP_ROOT}"

case "${SCENARIO^^}" in
  C3)
    EXTRA=(
      -DCONFIG_IOMT_SCENARIO_C3=y
      -DCONFIG_IOMT_SCENARIO_C4=n
    )
    ;;
  C4)
    EXTRA=(
      -DCONFIG_IOMT_SCENARIO_C4=y
      -DCONFIG_IOMT_SCENARIO_C3=n
    )
    ;;
  *)
    echo "cenário inválido: ${SCENARIO}" >&2
    exit 2
    ;;
esac

case "${LOAD,,}" in
  low)
    EXTRA+=(-DCONFIG_IOMT_PUBLISH_PRESET_LOW=y -DCONFIG_IOMT_PUBLISH_PRESET_HIGH=n)
    ;;
  high)
    EXTRA+=(-DCONFIG_IOMT_PUBLISH_PRESET_HIGH=y -DCONFIG_IOMT_PUBLISH_PRESET_LOW=n)
    ;;
  *)
    echo "carga inválida: ${LOAD} (low|high)" >&2
    exit 2
    ;;
esac

echo "[build-scenario] ${SCENARIO^^} / hospital-${LOAD} — ${EXTRA[*]}"
idf.py set-target esp32 2>/dev/null || true
idf.py "${EXTRA[@]}" build

if [[ "${FLASH:-0}" == "1" ]]; then
  PORT="${ESPPORT:-/dev/ttyUSB0}"
  idf.py "${EXTRA[@]}" -p "${PORT}" flash
fi

echo "[build-scenario] OK — flash: FLASH=1 ESPPORT=${ESPPORT:-/dev/ttyUSB0} $0 ${SCENARIO} ${LOAD}"
