#!/usr/bin/env bash
# Coleta CPU/RAM no Pi (ou host Linux) durante benchmarks C1/C2.
set -euo pipefail
DURATION="${1:-10}"
INTERVAL="${2:-1}"
OUT="${3:-/tmp/iomt-metrics.csv}"

echo "timestamp,load_1m,mem_used_mb,mem_total_mb" > "${OUT}"
end=$((SECONDS + DURATION))
while [[ ${SECONDS} -lt ${end} ]]; do
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  mem_avail_kb="$(awk '/MemAvailable/ {print $2}' /proc/meminfo)"
  mem_total_kb="$(awk '/MemTotal/ {print $2}' /proc/meminfo)"
  used_mb=$(( (mem_total_kb - mem_avail_kb) / 1024 ))
  total_mb=$(( mem_total_kb / 1024 ))
  load="$(awk '{print $1}' /proc/loadavg)"
  echo "${ts},${load},${used_mb},${total_mb}" >> "${OUT}"
  sleep "${INTERVAL}"
done
echo "Métricas em ${OUT}"
