#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRYPTO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
export LIBOQS_PREFIX="${LIBOQS_PREFIX:-${CRYPTO_ROOT}/lib}"
export PKG_CONFIG_PATH="${LIBOQS_PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
export LD_LIBRARY_PATH="${LIBOQS_PREFIX}/lib:${LD_LIBRARY_PATH:-}"
export CGO_ENABLED=1

cd "${CRYPTO_ROOT}"
go test -v ./...
