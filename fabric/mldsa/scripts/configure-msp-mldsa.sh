#!/usr/bin/env bash
# Prepara MSP ML-DSA de laboratório e documenta limitações do test-network Docker.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

echo "[network=mldsa] Gerando chaves ML-DSA User1 (lab)..."
"${REPO_ROOT}/crypto/scripts/gen-msp-mldsa-lab.sh" "${MLDSA_ROOT:-${SCRIPT_DIR}/..}/lab-msp/org1/user1"

echo ""
echo "==> MSP ML-DSA gerado em fabric/mldsa/lab-msp/"
echo "    Config BCCSP: fabric/mldsa/config/bccsp.yaml"
echo ""
echo "Peers: imagem tcc/fabric-peer-mldsa (./scripts/build-peer-image.sh) com liboqs."
echo "MSP ML-DSA: msp-mldsa-sign + test-msp-mldsa-endorse.sh (on-chain)"
echo "Envelope Fabric CA: ECDSA — crypto/docs/p2-escopo-msp.md"
echo ""
echo "Fechamento P2: ./scripts/close-pilar-2.sh"
