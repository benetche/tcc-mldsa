#!/usr/bin/env bash
# Benchmark C3/C4 com ESP32 real via ponte MQTT → Fabric.
#
# Uso:
#   ./run-esp32-benchmark.sh C3 hospital-low --samples 30 --warmup 10
#   MQTT_HOST=192.168.0.10 ./run-esp32-benchmark.sh C3 hospital-high
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

SCENARIO="${1:?C3 ou C4}"
LOAD="${2:-hospital-low}"
shift 2 || true
EXTRA=("$@")

export REPO_ROOT="${REPO_ROOT}"
export IOMT_ESP32_BRIDGE="${IOMT_ESP32_BRIDGE:-mqtt}"
: "${MQTT_HOST:?Defina MQTT_HOST (IP do broker Mosquitto)}"
export MQTT_HOST
export MQTT_PORT="${MQTT_PORT:-1883}"
export IOMT_DEVICE_ID="${IOMT_DEVICE_ID:-esp32-ward-01}"
export FABRIC_PEER_ENDPOINT="${FABRIC_PEER_ENDPOINT:-localhost:7051}"

case "${SCENARIO^^}" in
  C3) export FABRIC_NETWORK=baseline ;;
  C4) export FABRIC_NETWORK=mldsa ;;
  *)
    echo "cenário inválido: ${SCENARIO}" >&2
    exit 2
    ;;
esac

if [[ -d "${REPO_ROOT}/scripts/ingestion/.venv" ]]; then
  # shellcheck disable=SC1091
  source "${REPO_ROOT}/scripts/ingestion/.venv/bin/activate"
fi

echo "[run-esp32-benchmark] ${SCENARIO}/${LOAD} bridge=${IOMT_ESP32_BRIDGE} mqtt=${MQTT_HOST}:${MQTT_PORT}"
exec "${REPO_ROOT}/benchmarks/scripts/run_suite.sh" \
  --scenario "${SCENARIO^^}" \
  --load "${LOAD}" \
  --samples 30 \
  --warmup 10 \
  "${EXTRA[@]}"
