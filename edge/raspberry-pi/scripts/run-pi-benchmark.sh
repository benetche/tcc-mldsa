#!/usr/bin/env bash
# Benchmark C1/C2 executado no Raspberry Pi (peer CLI local → Fabric no PC).
# Uso no Pi:
#   ./scripts/run-pi-benchmark.sh C1 hospital-low --samples 30 --warmup 10
set -euo pipefail
SCENARIO="${1:?C1 ou C2}"
LOAD="${2:-hospital-low}"
shift 2 || true

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PI_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_ROOT="${REPO_ROOT:-$(cd "${PI_ROOT}/../.." && pwd)}"

if [[ -f "${PI_ROOT}/config.env" ]]; then
  # shellcheck disable=SC1091
  source "${PI_ROOT}/config.env"
fi

case "${SCENARIO}" in
  C1) NETWORK=baseline; SCEN_FILE=c1-pi-baseline.yaml ;;
  C2) NETWORK=mldsa; SCEN_FILE=c2-pi-mldsa.yaml ;;
  *) echo "cenário inválido: ${SCENARIO}" >&2; exit 2 ;;
esac

export FABRIC_NETWORK="${NETWORK}"
export REPO_ROOT="${REPO_ROOT}"

SAMPLES=30
WARMUP=10
EXTRA=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --samples) SAMPLES="$2"; shift 2 ;;
    --warmup) WARMUP="$2"; shift 2 ;;
    *) EXTRA+=("$1"); shift ;;
  esac
done

ING="${REPO_ROOT}/scripts/ingestion"
if [[ -d "${ING}/.venv" ]]; then
  # shellcheck disable=SC1091
  source "${ING}/.venv/bin/activate"
elif [[ -d "${ING}" ]]; then
  python3 -m venv "${ING}/.venv"
  # shellcheck disable=SC1091
  source "${ING}/.venv/bin/activate"
  pip install -q -r "${ING}/requirements.txt"
fi

SCEN_DIR="${REPO_ROOT}/benchmarks/scenarios"
OUT_DIR="${REPO_ROOT}/benchmarks/results/$(date +%Y%m%d-%H%M%S)-${SCENARIO}-${LOAD}-on-pi"
SUFFIX="pi_${SCENARIO}_$(date +%s)"

echo "[run-pi-benchmark] ${SCENARIO}/${LOAD} network=${NETWORK} samples=${SAMPLES} → ${OUT_DIR}"
python3 "${REPO_ROOT}/benchmarks/scripts/bench_lib.py" \
  --scenario-file "${SCEN_DIR}/${SCEN_FILE}" \
  --load-file "${SCEN_DIR}/${LOAD}.yaml" \
  --network "${NETWORK}" \
  --samples "${SAMPLES}" \
  --warmup "${WARMUP}" \
  --out-dir "${OUT_DIR}" \
  --id-suffix "${SUFFIX}" \
  "${EXTRA[@]}"

echo "OK: benchmark no Pi → ${OUT_DIR}"
