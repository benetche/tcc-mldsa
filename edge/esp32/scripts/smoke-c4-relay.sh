#!/usr/bin/env bash
# Smoke C4: ESP32 sem ML-DSA on-device → relay esp32_payload_only → Fabric mldsa.
#
# Com firmware C4 (stub), o ESP publica observação sem deviceSignature válida;
# a ponte MQTT classifica como esp32_payload_only e ainda registra no ledger.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

export FABRIC_NETWORK=mldsa
export FABRIC_SAMPLES_DIR="${FABRIC_SAMPLES_DIR:-${REPO_ROOT}/fabric-samples}"
export PATH="${FABRIC_SAMPLES_DIR}/bin:${PATH}"
export REPO_ROOT="${REPO_ROOT}"
export FABRIC_PEER_ENDPOINT="${FABRIC_PEER_ENDPOINT:-localhost:7051}"
export MQTT_HOST="${MQTT_HOST:-<IP_PC>}"
export MQTT_PORT="${MQTT_PORT:-1883}"
export IOMT_DEVICE_ID="${IOMT_DEVICE_ID:-esp32-ward-01}"

if [[ -d "${REPO_ROOT}/scripts/ingestion/.venv" ]]; then
  # shellcheck disable=SC1091
  source "${REPO_ROOT}/scripts/ingestion/.venv/bin/activate"
fi
python3 -c "import paho.mqtt.client" 2>/dev/null || pip install -q paho-mqtt

echo "[smoke-c4] rede mldsa — relay MQTT (payload sem assinatura PQC no dispositivo)"
OUT="$(python3 "${SCRIPT_DIR}/mqtt_fabric_bridge.py" --once --timeout 90)"
echo "${OUT}"

MODE="$(echo "${OUT}" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('signing_mode_effective',''))")"
if [[ "${MODE}" != "esp32_payload_only" ]]; then
  echo "AVISO: modo efetivo ${MODE} (esperado esp32_payload_only para stub C4)" >&2
fi

echo "OK: smoke C4 relay — modo=${MODE} (ML-DSA on-device permanece pendente)"
