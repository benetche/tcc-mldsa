#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

require_fabric_samples
TN="$(test_network_dir)"
export PATH="${FABRIC_SAMPLES_DIR}/bin:${PATH}"

cd "${TN}"
./network.sh down
echo "[network=baseline] Rede encerrada."
