#!/usr/bin/env bash
# Suíte de benchmark P4 — matriz C1–C4 × hospital-low/high.
#
# Uso:
#   ./run_suite.sh --all
#   ./run_suite.sh --scenario C1 --load hospital-high
#   ./run_suite.sh --all --dry-run
#   ./run_suite.sh --scenario C1 --samples 30 --warmup 10
#
# Resultados (gitignored): benchmarks/results/<timestamp>-Cx-load/
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
SCEN_DIR="${ROOT}/benchmarks/scenarios"
RESULTS_DIR="${ROOT}/benchmarks/results"

SCENARIOS=()
LOADS=()
DRY_RUN=""
SAMPLES=""
WARMUP=""
SUFFIX="$(date +%Y%m%d-%H%M%S)"

declare -A SCEN_FILE=(
  [C1]="c1-pi-baseline.yaml"
  [C2]="c2-pi-mldsa.yaml"
  [C3]="c3-esp32-baseline.yaml"
  [C4]="c4-esp32-mldsa.yaml"
)

usage() { sed -n '2,14p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --all) SCENARIOS=(C1 C2 C3 C4); shift ;;
    --scenario) SCENARIOS+=("$2"); shift 2 ;;
    --load) LOADS+=("$2"); shift 2 ;;
    --samples) SAMPLES="$2"; shift 2 ;;
    --warmup) WARMUP="$2"; shift 2 ;;
    --dry-run) DRY_RUN="--dry-run"; shift ;;
    -h|--help) usage 0 ;;
    *) echo "arg desconhecido: $1" >&2; usage 1 ;;
  esac
done

[[ ${#SCENARIOS[@]} -eq 0 ]] && { echo "informe --all ou --scenario Cx" >&2; usage 1; }
[[ ${#LOADS[@]} -eq 0 ]] && LOADS=(hospital-low hospital-high)

# Ambiente Python (reaproveita venv da ingestão P3)
if [[ -d "${ROOT}/scripts/ingestion/.venv" ]]; then
  # shellcheck disable=SC1091
  source "${ROOT}/scripts/ingestion/.venv/bin/activate"
elif [[ -d "${ROOT}/benchmarks/.venv" ]]; then
  # shellcheck disable=SC1091
  source "${ROOT}/benchmarks/.venv/bin/activate"
fi
python3 -c "import yaml" 2>/dev/null || pip install -q -r "${ROOT}/benchmarks/requirements.txt"

export REPO_ROOT="${ROOT}"
mkdir -p "${RESULTS_DIR}"

echo "[run_suite] cenários: ${SCENARIOS[*]} | cargas: ${LOADS[*]} ${DRY_RUN}"
run_count=0
for sc in "${SCENARIOS[@]}"; do
  sc_upper="${sc^^}"
  file="${SCEN_FILE[${sc_upper}]:-}"
  [[ -z "${file}" ]] && { echo "cenário inválido: ${sc}" >&2; continue; }
  scen_path="${SCEN_DIR}/${file}"
  for load in "${LOADS[@]}"; do
    load_path="${SCEN_DIR}/${load}.yaml"
    [[ -f "${load_path}" ]] || { echo "carga ausente: ${load_path}" >&2; continue; }
    out_dir="${RESULTS_DIR}/${SUFFIX}-${sc_upper}-${load}"
    extra=()
    [[ -n "${SAMPLES}" ]] && extra+=(--samples "${SAMPLES}")
    [[ -n "${WARMUP}" ]] && extra+=(--warmup "${WARMUP}")
    [[ -n "${DRY_RUN}" ]] && extra+=(--dry-run)
    python3 "${SCRIPT_DIR}/bench_lib.py" \
      --scenario-file "${scen_path}" \
      --load-file "${load_path}" \
      --out-dir "${out_dir}" \
      --id-suffix "${SUFFIX}-${sc_upper}-${load}" \
      "${extra[@]}"
    ((run_count++)) || true
  done
done

echo "[run_suite] ${run_count} execução(ões) concluída(s). Resultados em ${RESULTS_DIR}/${SUFFIX}-*"
echo "[run_suite] Análise: python3 ${SCRIPT_DIR}/analyze.py --glob '${SUFFIX}-*'"
