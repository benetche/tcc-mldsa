#!/usr/bin/env bash
# Dispara benchmark C1/C2 no Raspberry Pi via SSH (após deploy).
# Uso:
#   ./run_suite_pi.sh --deploy C1 hospital-low --samples 30
#   ./run_suite_pi.sh C2 hospital-high --samples 30 --warmup 10
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
PI_SCRIPTS="${REPO_ROOT}/edge/raspberry-pi/scripts"

DO_DEPLOY=0
ARGS=()
for arg in "$@"; do
  if [[ "${arg}" == "--deploy" ]]; then
    DO_DEPLOY=1
  else
    ARGS+=("${arg}")
  fi
done

[[ ${#ARGS[@]} -ge 2 ]] || {
  echo "uso: $0 [--deploy] C1|C2 hospital-low|hospital-high [--samples N] [--warmup N]" >&2
  exit 1
}

if [[ "${DO_DEPLOY}" -eq 1 ]]; then
  SYNC_FHIR=1 "${PI_SCRIPTS}/deploy-to-pi.sh"
fi

# shellcheck disable=SC1091
source "${PI_SCRIPTS}/lib-ssh-pi.sh"
setup_ssh_pi
REMOTE_BASE="$(run_ssh_pi "echo \"\${HOME}/${PI_REMOTE_SUBDIR:-tcc-iomt}\"")"

echo "[run_suite_pi] ${PI_USER}@${PI_HOST} — ${ARGS[*]}"
REMOTE_CMD="$(printf '%q ' "${ARGS[@]}")"
run_ssh_pi "bash -lc 'cd \"${REMOTE_BASE}/edge/raspberry-pi\" && source config.env && ./scripts/run-pi-benchmark.sh ${REMOTE_CMD}'"
