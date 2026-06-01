# shellcheck shell=bash
# Funções SSH compartilhadas — source por scripts edge/raspberry-pi.
# Requer lab.env com PI_HOST, PI_USER.

setup_ssh_pi() {
  local _lib_dir
  _lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  PI_ROOT="$(cd "${_lib_dir}/.." && pwd)"
  LAB_ENV="${PI_ROOT}/lab.env"
  [[ -f "${LAB_ENV}" ]] || { echo "ERRO: ${LAB_ENV} ausente" >&2; return 1; }
  # shellcheck disable=SC1090
  source "${LAB_ENV}"
  PI_HOST="${PI_HOST:?PI_HOST em lab.env}"
  PI_USER="${PI_USER:?PI_USER em lab.env}"
  PI_REMOTE_SUBDIR="${PI_REMOTE_SUBDIR:-tcc-iomt}"
  SSH_OPTS=(-o StrictHostKeyChecking=accept-new -o ConnectTimeout=15)
  SSH_WRAPPER=()
  RSYNC_RSH=""
  if [[ -n "${PI_SSH_KEY:-}" ]]; then
    SSH_OPTS+=(-i "${PI_SSH_KEY}")
  elif [[ -n "${PI_SSH_PASSWORD:-}" ]]; then
    if command -v sshpass &>/dev/null; then
      export SSHPASS="${PI_SSH_PASSWORD}"
      SSH_WRAPPER=(sshpass -e)
    else
      ASKPASS_SCRIPT="$(mktemp)"
      printf '#!/bin/sh\necho %s\n' "${PI_SSH_PASSWORD}" > "${ASKPASS_SCRIPT}"
      chmod 700 "${ASKPASS_SCRIPT}"
      export SSH_ASKPASS="${ASKPASS_SCRIPT}"
      export SSH_ASKPASS_REQUIRE=force
      export DISPLAY="${DISPLAY:-:0}"
      SSH_WRAPPER=(setsid)
    fi
  fi
  [[ -z "${RSYNC_RSH}" ]] && RSYNC_RSH="ssh ${SSH_OPTS[*]}"
}

run_ssh_pi() {
  "${SSH_WRAPPER[@]}" ssh "${SSH_OPTS[@]}" "${PI_USER}@${PI_HOST}" "$@"
}
