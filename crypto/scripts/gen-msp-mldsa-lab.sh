#!/usr/bin/env bash
# Gera material MSP de laboratório com chaves ML-DSA-65 (liboqs) — User1 org1.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRYPTO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_ROOT="$(cd "${CRYPTO_ROOT}/.." && pwd)"
OUT="${1:-${REPO_ROOT}/fabric/mldsa/lab-msp/org1/user1}"

export LIBOQS_PREFIX="${LIBOQS_PREFIX:-${CRYPTO_ROOT}/lib}"
export PKG_CONFIG_PATH="${LIBOQS_PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
export LD_LIBRARY_PATH="${LIBOQS_PREFIX}/lib:${LD_LIBRARY_PATH:-}"
export CGO_ENABLED=1

cd "${CRYPTO_ROOT}"
mkdir -p "${OUT}/keystore" "${OUT}/signcerts"

go run ./cmd/gen-msp-mldsa/ -out "${OUT}"

echo "OK: MSP ML-DSA em ${OUT}"
echo "    keystore/*_sk  signcerts/cert.pem  (formato liboqs, não X.509)"
