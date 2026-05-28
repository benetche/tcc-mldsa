#!/usr/bin/env bash
# Valida BCCSP ML-DSA no binário peer (container) via bccsp-smoke.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
CRYPTO="${REPO_ROOT}/crypto"
PEER="${1:-peer0.org1.example.com}"

export LIBOQS_PREFIX="${LIBOQS_PREFIX:-${CRYPTO}/lib}"
export PKG_CONFIG_PATH="${LIBOQS_PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
export LD_LIBRARY_PATH="${LIBOQS_PREFIX}/lib:${LD_LIBRARY_PATH:-}"
export CGO_ENABLED=1

BIN="/tmp/bccsp-smoke-$$"
(cd "${CRYPTO}" && go build -o "${BIN}" ./cmd/bccsp-smoke/)

docker cp "${BIN}" "${PEER}:/tmp/bccsp-smoke"
docker exec "${PEER}" chmod +x /tmp/bccsp-smoke
out="$(docker exec "${PEER}" /tmp/bccsp-smoke)"
rm -f "${BIN}"
echo "${out}"
echo "[network=mldsa] test-peer-bccsp-mldsa OK (${PEER})"
