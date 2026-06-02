#!/usr/bin/env bash
# Smoke E2E C3: ESP32 publica observação assinada (MQTT) → ponte → Fabric baseline.
#
# Pré-requisitos:
#   - Rede Fabric baseline UP (peer localhost:7051)
#   - Mosquitto acessível (MQTT_HOST, default <IP_PC>:1883)
#   - ESP32 flashado (C3), publicando em iomt/esp32/{device_id}/observation
#
# Uso:
#   MQTT_HOST=<IP_PC> ./scripts/smoke-e2e-c3.sh
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

export FABRIC_NETWORK="${FABRIC_NETWORK:-baseline}"
export FABRIC_SAMPLES_DIR="${FABRIC_SAMPLES_DIR:-${REPO_ROOT}/fabric-samples}"
export PATH="${FABRIC_SAMPLES_DIR}/bin:${PATH}"
export REPO_ROOT="${REPO_ROOT}"
export FABRIC_PEER_ENDPOINT="${FABRIC_PEER_ENDPOINT:-localhost:7051}"
export MQTT_HOST="${MQTT_HOST:-<IP_PC>}"
export MQTT_PORT="${MQTT_PORT:-1883}"
export IOMT_DEVICE_ID="${IOMT_DEVICE_ID:-esp32-ward-01}"

if ! command -v peer >/dev/null 2>&1; then
  echo "ERRO: peer CLI ausente (FABRIC_SAMPLES_DIR=${FABRIC_SAMPLES_DIR})" >&2
  exit 1
fi

if ! peer channel list 2>/dev/null | grep -q iomtchannel; then
  echo "ERRO: canal iomtchannel indisponível — suba fabric/baseline" >&2
  exit 1
fi

# paho-mqtt ou Mosquitto no Docker
if [[ -d "${REPO_ROOT}/scripts/ingestion/.venv" ]]; then
  # shellcheck disable=SC1091
  source "${REPO_ROOT}/scripts/ingestion/.venv/bin/activate"
fi
python3 -c "import paho.mqtt.client" 2>/dev/null || pip install -q paho-mqtt

echo "[smoke-c3] MQTT ${MQTT_HOST}:${MQTT_PORT} device=${IOMT_DEVICE_ID} → Fabric (${FABRIC_NETWORK})"
echo "[smoke-c3] aguardando observação do ESP32 (timeout 90s)..."

OUT="$(python3 "${SCRIPT_DIR}/mqtt_fabric_bridge.py" --once --timeout 90 2>/dev/null)"
echo "${OUT}"

parse_json() {
  python3 -c "import json,sys; d=json.load(sys.stdin); print($1)" <<<"${OUT}"
}

SIGN_ALG="$(parse_json "d.get('signAlg') or d.get('ledger',{}).get('signAlg','')")"
MODE="$(parse_json "d.get('signing_mode_effective','')")"

if [[ -z "${SIGN_ALG}" ]]; then
  echo "ERRO: signAlg ausente no ledger" >&2
  exit 1
fi

if [[ "${SIGN_ALG}" != "ECDSA-P256" ]]; then
  echo "ERRO: C3 espera ECDSA-P256 no ledger, obteve ${SIGN_ALG}" >&2
  exit 1
fi

if [[ "${MODE}" != "esp32_direct" ]]; then
  echo "AVISO: signing_mode_effective=${MODE} (esperado esp32_direct com assinatura on-device)" >&2
fi

echo "OK: smoke E2E C3 — ${SIGN_ALG} on-chain (mode=${MODE})"
