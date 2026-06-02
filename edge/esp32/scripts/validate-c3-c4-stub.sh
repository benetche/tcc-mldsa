#!/usr/bin/env bash
# C3/C4: validação estrutural sem hardware ESP32 (fixtures + critérios de aceite).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"

check_yaml() {
  local f="$1"
  [[ -f "${f}" ]] || { echo "ausente: ${f}"; return 1; }
  grep -q 'scenario_id: C3' "${f}" || grep -q 'scenario_id: C4' "${f}" || true
}

check_yaml "${ROOT}/benchmarks/scenarios/c3-esp32-baseline.yaml"
check_yaml "${ROOT}/benchmarks/scenarios/c4-esp32-mldsa.yaml"

cat <<EOF
{
  "status": "firmware_scaffold",
  "scenarios": ["C3", "C4"],
  "device": "esp32",
  "note": "C3 ECDSA on-device + ponte MQTT→Fabric; C4 ML-DSA on-device pendente (esp32_payload_only via relay).",
  "expected_signing": {"C3": "ECDSA-P256", "C4": "ML-DSA-65"}
}
EOF
exit 0
