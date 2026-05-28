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
echo "MSP de transação nos peers ainda ECDSA (Fabric CA). Próximo passo:"
echo "  identidade X.509/ML-DSA ou MSP custom para assinatura E2E nos nós."
echo ""
echo "Primitivas validadas: crypto/bccsp/fabric + test-mldsa.sh"
echo "Cliente Pi (C2): usa peer-cli com MSP ECDSA do test-network até migração completa."
