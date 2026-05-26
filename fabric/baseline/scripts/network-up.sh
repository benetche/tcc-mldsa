#!/usr/bin/env bash
# Sobe test-network Fabric e cria canal iomtchannel.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

require_fabric_samples
TN="$(test_network_dir)"
export PATH="${FABRIC_SAMPLES_DIR}/bin:${PATH}"
export FABRIC_CFG_PATH="${TN}/../config/"

cd "${TN}"
echo "[network=baseline] Subindo test-network..."
./network.sh up createChannel -c "${CHANNEL_NAME}" -ca

echo "[network=baseline] Canal ${CHANNEL_NAME} pronto."
