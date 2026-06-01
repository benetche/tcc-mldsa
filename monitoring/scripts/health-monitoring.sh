#!/usr/bin/env bash
# Valida a stack de monitoramento: containers, Prometheus targets e Grafana.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MON_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
PROM="${PROM_URL:-http://localhost:9090}"
GRAFANA="${GRAFANA_URL:-http://localhost:3000}"

fail=0
ok()   { echo "OK:   $*"; }
warn() { echo "WARN: $*"; }
bad()  { echo "FAIL: $*"; fail=1; }

echo "[health] containers"
for c in iomt-prometheus iomt-grafana iomt-node-exporter iomt-cadvisor; do
  if docker ps --format '{{.Names}}' | grep -q "^${c}$"; then
    ok "${c} up"
  else
    bad "${c} ausente (docker compose up -d)"
  fi
done

echo "[health] Prometheus targets"
if curl -sf "${PROM}/api/v1/targets" >/tmp/mon-targets.json 2>/dev/null; then
  up=$(python3 -c "import json;d=json.load(open('/tmp/mon-targets.json'));print(sum(1 for t in d['data']['activeTargets'] if t['health']=='up'))" 2>/dev/null || echo 0)
  total=$(python3 -c "import json;d=json.load(open('/tmp/mon-targets.json'));print(len(d['data']['activeTargets']))" 2>/dev/null || echo 0)
  ok "Prometheus respondendo — ${up}/${total} targets up"
  [[ "${up}" -eq 0 ]] && warn "nenhum target up ainda (aguarde scrape_interval)"
else
  bad "Prometheus não respondeu em ${PROM}"
fi

echo "[health] Grafana"
if curl -sf "${GRAFANA}/api/health" >/tmp/mon-grafana.json 2>/dev/null; then
  ok "Grafana respondendo ($(python3 -c "import json;print(json.load(open('/tmp/mon-grafana.json')).get('database','?'))" 2>/dev/null || echo ok))"
else
  warn "Grafana não respondeu em ${GRAFANA} (pode ainda estar iniciando)"
fi

echo "[health] ESP32/MQTT (perfil mqtt — opcional)"
if docker ps --format '{{.Names}}' | grep -q '^iomt-telegraf$'; then
  if curl -sf "http://localhost:9273/metrics" >/dev/null 2>&1; then
    ok "Telegraf expondo :9273"
  else
    warn "Telegraf up mas sem métricas (publique via mqtt-esp32-simulator.py)"
  fi
else
  warn "perfil mqtt inativo (docker compose --profile mqtt up -d)"
fi

[[ "${fail}" -eq 0 ]] && echo "OK: monitoramento saudável" || { echo "FALHA na validação"; exit 1; }
