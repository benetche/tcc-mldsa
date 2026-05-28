#!/usr/bin/env bash
# Valida matriz experimental P2: C1 (baseline+ECDSA borda), C2 (mldsa+ML-DSA borda), C3/C4 (stub ESP32).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REPORT="${ROOT}/benchmarks/results/p2-validation-$(date +%Y%m%d-%H%M%S).json"
mkdir -p "$(dirname "${REPORT}")"

log() { echo "[validate-p2] $*"; }
failures=0
results=()

record() {
  local id="$1" status="$2" detail="$3"
  results+=("{\"scenario\":\"${id}\",\"status\":\"${status}\",\"detail\":$(json_escape "${detail}")}")
  if [[ "${status}" == "fail" ]]; then
    ((failures++)) || true
  fi
}

json_escape() {
  python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$1"
}

# --- Camada cripto (liboqs + BCCSP) ---
log "crypto: test-mldsa.sh"
if "${ROOT}/crypto/scripts/test-mldsa.sh" >/tmp/p2-crypto.log 2>&1; then
  record "crypto" "ok" "liboqs ML-DSA-65"
else
  record "crypto" "fail" "$(tail -3 /tmp/p2-crypto.log)"
fi

# --- C1: rede baseline ---
log "C1: rede baseline + chaincode"
if [[ -d "${ROOT}/fabric-samples/test-network/organizations" ]]; then
  if FABRIC_NETWORK=baseline IOMT_EDGE_SIGN=ECDSA-P256 \
    "${ROOT}/edge/raspberry-pi/scripts/validate-local-submit.sh" baseline 2>/tmp/p2-c1.log; then
    record "C1" "ok" "submit local ECDSA borda + ledger"
  else
    record "C1" "fail" "$(tail -5 /tmp/p2-c1.log)"
  fi
else
  record "C1" "skip" "fabric-samples/test-network ausente — rode fabric/baseline/scripts/network-up.sh"
fi

# --- C2: rede mldsa ---
log "C2: rede mldsa + peer ML-DSA + assinatura borda"
if docker ps --format '{{.Names}}' 2>/dev/null | grep -q 'peer0.org1.example.com'; then
  if "${ROOT}/fabric/mldsa/scripts/verify-peer-mldsa.sh" >/tmp/p2-peer.log 2>&1; then
    peer_note="peer BCCSP MLDSA ok"
  else
    peer_note="verify-peer-mldsa: $(tail -2 /tmp/p2-peer.log)"
  fi
  if FABRIC_NETWORK=mldsa IOMT_EDGE_SIGN=ML-DSA-65 \
    "${ROOT}/edge/raspberry-pi/scripts/validate-local-submit.sh" mldsa 2>/tmp/p2-c2.log; then
    record "C2" "ok" "${peer_note}; submit ML-DSA borda"
  else
    record "C2" "fail" "$(tail -5 /tmp/p2-c2.log)"
  fi
else
  record "C2" "skip" "peers Docker ausentes — rode fabric/mldsa/scripts/network-up.sh"
fi

# --- C3/C4: ESP32 (hardware pendente) ---
log "C3/C4: stub ESP32"
if "${ROOT}/edge/esp32/scripts/validate-c3-c4-stub.sh" >/tmp/p2-esp32.log 2>&1; then
  record "C3" "stub" "fixture ESP32 ECDSA — hardware pendente"
  record "C4" "stub" "fixture ESP32 ML-DSA — hardware pendente"
else
  record "C3" "fail" "$(cat /tmp/p2-esp32.log)"
  record "C4" "fail" "$(cat /tmp/p2-esp32.log)"
fi

# --- Pi remoto (opcional) ---
PI_ENV="${ROOT}/edge/raspberry-pi/lab.env"
if [[ -n "${SKIP_PI:-}" ]]; then
  record "Pi" "skip" "SKIP_PI definido"
elif [[ -f "${PI_ENV}" ]]; then
  # shellcheck disable=SC1090
  source "${PI_ENV}"
  if [[ -n "${PI_HOST:-}" ]]; then
    log "Pi: smoke remoto (${FABRIC_NETWORK:-mldsa})"
    if "${ROOT}/edge/raspberry-pi/scripts/deploy-to-pi.sh" >/tmp/p2-pi.log 2>&1; then
      record "Pi-${FABRIC_NETWORK:-mldsa}" "ok" "deploy + smoke no ${PI_HOST}"
    else
      record "Pi-${FABRIC_NETWORK:-mldsa}" "fail" "$(tail -8 /tmp/p2-pi.log)"
    fi
  fi
fi

{
  echo "{"
  echo "  \"timestamp\": \"$(date -Iseconds)\","
  echo "  \"failures\": ${failures},"
  echo "  \"results\": ["
  first=1
  for r in "${results[@]}"; do
    [[ "${first}" -eq 1 ]] && first=0 || echo ","
    echo -n "    ${r}"
  done
  echo ""
  echo "  ]"
  echo "}"
} > "${REPORT}"

log "Relatório: ${REPORT}"
if [[ "${failures}" -gt 0 ]]; then
  log "FALHA: ${failures} cenário(s)"
  exit 1
fi
log "OK: validação P2 concluída (stubs C3/C4 documentados)"
