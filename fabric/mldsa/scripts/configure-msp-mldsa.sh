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
echo "Limitação atual: containers peer do test-network usam imagem hyperledger/fabric-peer"
echo "com MSP ECDSA da Fabric CA. Para assinatura E2E ML-DSA nos peers:"
echo "  1. Imagem Docker custom com peer de fabric/mldsa/bin + liboqs"
echo "  2. Montar bccsp.yaml e MSP ML-DSA no peer"
echo ""
echo "Primitivas validadas: crypto/bccsp/fabric + test-mldsa.sh"
echo "Cliente Pi (C2): usa peer-cli com MSP ECDSA do test-network até migração completa."
