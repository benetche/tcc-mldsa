#!/usr/bin/env bash
# Gera tabela ECDSA P-256 vs ML-DSA-65 (liboqs) para a monografia.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRYPTO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
OUT="${1:-${CRYPTO_ROOT}/docs/ecdsa-vs-mldsa.md}"

export LIBOQS_PREFIX="${LIBOQS_PREFIX:-${CRYPTO_ROOT}/lib}"
export PKG_CONFIG_PATH="${LIBOQS_PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
export LD_LIBRARY_PATH="${LIBOQS_PREFIX}/lib:${LD_LIBRARY_PATH:-}"
export CGO_ENABLED=1

cd "${CRYPTO_ROOT}"
mkdir -p "$(dirname "${OUT}")"
go run ./cmd/benchmark-crypto/ -out "${OUT}"
echo "Tabela em ${OUT}"
