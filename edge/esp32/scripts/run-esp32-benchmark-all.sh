#!/usr/bin/env bash
# Benchmarks formais ESP32: C3 e C4 × hospital-low/high (≥30 amostras cada).
# Requer: Fabric baseline (C3), mldsa (C4), Mosquitto, ESP publicando no broker.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

: "${MQTT_HOST:?Defina MQTT_HOST (IP do broker Mosquitto)}"
export MQTT_HOST
export IOMT_ESP32_BRIDGE=mqtt
export FABRIC_PEER_ENDPOINT="${FABRIC_PEER_ENDPOINT:-localhost:7051}"

run_one() {
  local sc="$1" load="$2"
  echo ""
  echo "========== ${sc} / hospital-${load} =========="
  "${SCRIPT_DIR}/run-esp32-benchmark.sh" "${sc}" "hospital-${load}" --samples 30 --warmup 10
}

run_one C3 low
run_one C3 high
run_one C4 low
run_one C4 high

echo ""
echo "[run-esp32-benchmark-all] concluído — analyze:"
echo "  python3 ${REPO_ROOT}/benchmarks/scripts/analyze.py --glob '*-C3-*' '*-C4-*'"
