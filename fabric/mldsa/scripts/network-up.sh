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
echo "[network=mldsa] Subindo test-network..."
./network.sh up createChannel -c "${CHANNEL_NAME}" -ca

echo "[network=mldsa] Canal ${CHANNEL_NAME} pronto."

echo "[network=mldsa] Ativando peers com imagem ML-DSA (liboqs)..."
"${SCRIPT_DIR}/switch-peers-mldsa.sh"
