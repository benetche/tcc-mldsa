#!/usr/bin/env bash
# Checklist de fechamento do Pilar 2 (criptografia + rede mldsa).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

echo "==> P2.1 crypto"
"${REPO_ROOT}/crypto/scripts/test-mldsa.sh"

echo "==> Peer BCCSP ML-DSA"
"${SCRIPT_DIR}/verify-peer-mldsa.sh"
"${SCRIPT_DIR}/test-peer-bccsp-mldsa.sh"

echo "==> Chaincode + MSP ML-DSA on-chain"
"${SCRIPT_DIR}/test-chaincode.sh"
"${SCRIPT_DIR}/test-msp-mldsa-endorse.sh"

echo "==> Matriz C1–C4 (local)"
SKIP_PI=1 "${REPO_ROOT}/benchmarks/scripts/validate-p2-scenarios.sh"

echo ""
echo "OK: Pilar 2 — validação de fechamento concluída"
