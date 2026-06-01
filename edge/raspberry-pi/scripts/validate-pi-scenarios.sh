#!/usr/bin/env bash
# Valida cenários C1/C2 no Pi: smoke remoto, node_exporter, FHIR opcional.
# Uso: ./validate-pi-scenarios.sh [--deploy] [--skip-remote]
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PI_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_ROOT="$(cd "${PI_ROOT}/../.." && pwd)"
REPORT="${REPO_ROOT}/benchmarks/results/pi-validation-$(date +%Y%m%d-%H%M%S).json"
mkdir -p "$(dirname "${REPORT}")"

DO_DEPLOY=0
SKIP_REMOTE=0
for arg in "$@"; do
  case "$arg" in
    --deploy) DO_DEPLOY=1 ;;
    --skip-remote) SKIP_REMOTE=1 ;;
  esac
done

log() { echo "[validate-pi] $*"; }
failures=0
results=()

record() {
  local id="$1" status="$2" detail="$3"
  results+=("{\"check\":\"${id}\",\"status\":\"${status}\",\"detail\":$(python3 -c 'import json,sys;print(json.dumps(sys.argv[1]))' "$detail")}")
  [[ "${status}" == "fail" ]] && ((failures++)) || true
}

# --- Local (host dev) ---
log "local: validate-local-submit baseline"
if [[ -d "${REPO_ROOT}/fabric-samples/test-network/organizations" ]]; then
  if FABRIC_NETWORK=baseline IOMT_EDGE_SIGN=ECDSA-P256 \
    "${SCRIPT_DIR}/validate-local-submit.sh" baseline >/tmp/pi-v-c1.log 2>&1; then
    record "local-C1" "ok" "validate-local-submit baseline"
  else
    record "local-C1" "fail" "$(tail -3 /tmp/pi-v-c1.log)"
  fi
else
  record "local-C1" "skip" "rede Fabric ausente"
fi

log "local: validate-local-submit mldsa"
if [[ -d "${REPO_ROOT}/fabric-samples/test-network/organizations" ]]; then
  if FABRIC_NETWORK=mldsa IOMT_EDGE_SIGN=ML-DSA-65 \
    "${SCRIPT_DIR}/validate-local-submit.sh" mldsa >/tmp/pi-v-c2.log 2>&1; then
    record "local-C2" "ok" "validate-local-submit mldsa"
  else
    record "local-C2" "fail" "$(tail -5 /tmp/pi-v-c2.log)"
  fi
else
  record "local-C2" "skip" "rede Fabric ausente"
fi

# --- Deploy opcional ---
if [[ "${DO_DEPLOY}" -eq 1 ]]; then
  log "deploy-to-pi (FABRIC_NETWORK do lab.env)"
  if "${SCRIPT_DIR}/deploy-to-pi.sh" >/tmp/pi-deploy.log 2>&1; then
    record "deploy" "ok" "deploy-to-pi concluído"
  else
    record "deploy" "fail" "$(tail -8 /tmp/pi-deploy.log)"
  fi
fi

# --- Remoto (Pi físico) ---
if [[ "${SKIP_REMOTE}" -eq 0 ]]; then
  # shellcheck disable=SC1091
  source "${SCRIPT_DIR}/lib-ssh-pi.sh"
  setup_ssh_pi || { record "ssh" "fail" "lab.env/SSH"; SKIP_REMOTE=1; }
fi

if [[ "${SKIP_REMOTE}" -eq 0 ]]; then
  REMOTE_BASE="$(run_ssh_pi "echo \"\${HOME}/${PI_REMOTE_SUBDIR}\"")"
  log "Pi: ${PI_USER}@${PI_HOST}:${REMOTE_BASE}"

  log "Pi: node_exporter :9100"
  if run_ssh_pi "curl -sf --connect-timeout 3 http://127.0.0.1:9100/metrics | head -1" >/tmp/pi-ne.log 2>&1; then
    record "pi-node-exporter" "ok" "$(head -1 /tmp/pi-ne.log)"
  else
    record "pi-node-exporter" "warn" "node_exporter ausente — install-node-exporter.sh"
  fi

  log "Pi: smoke C1 (baseline)"
  if run_ssh_pi "bash -lc 'cd \"${REMOTE_BASE}/edge/raspberry-pi\" && source config.env && FABRIC_NETWORK=baseline ./scripts/smoke-c1.sh'" >/tmp/pi-smoke-c1.log 2>&1; then
    lat="$(grep -o '"latency_ms": [0-9]*' /tmp/pi-smoke-c1.log | head -1 || echo '')"
    record "pi-C1-smoke" "ok" "smoke C1 ${lat}"
  else
    record "pi-C1-smoke" "fail" "$(tail -5 /tmp/pi-smoke-c1.log)"
  fi

  log "Pi: smoke C2 (mldsa)"
  if run_ssh_pi "bash -lc 'cd \"${REMOTE_BASE}/edge/raspberry-pi\" && source config.env && FABRIC_NETWORK=mldsa ./scripts/smoke-c2.sh'" >/tmp/pi-smoke-c2.log 2>&1; then
    record "pi-C2-smoke" "ok" "smoke C2 $(grep signAlg /tmp/pi-smoke-c2.log | head -1 || true)"
  else
    record "pi-C2-smoke" "fail" "$(tail -5 /tmp/pi-smoke-c2.log)"
  fi

  if [[ -d "${REPO_ROOT}/scripts/ingestion" ]] && run_ssh_pi "test -f ${REMOTE_BASE}/scripts/ingestion/ingest_hospital.py" 2>/dev/null; then
    log "Pi: smoke FHIR"
    if run_ssh_pi "bash -lc 'cd \"${REMOTE_BASE}/edge/raspberry-pi\" && source config.env && FABRIC_NETWORK=baseline RUN_FHIR=0 ./scripts/smoke-fhir-pi.sh'" >/tmp/pi-fhir.log 2>&1; then
      record "pi-FHIR-smoke" "ok" "3 obs RegisterFhirObservation"
    else
      record "pi-FHIR-smoke" "fail" "$(tail -5 /tmp/pi-fhir.log)"
    fi
  else
    record "pi-FHIR-smoke" "skip" "rode deploy com SYNC_FHIR=1"
  fi
fi

{
  echo "{"
  echo "  \"timestamp\": \"$(date -Iseconds)\","
  echo "  \"pi_host\": \"${PI_HOST:-}\","
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
  log "FALHA: ${failures} check(s)"
  exit 1
fi
log "OK: validação Pi C1/C2"
