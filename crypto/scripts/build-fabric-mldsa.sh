#!/usr/bin/env bash
# Compila peer/orderer Fabric 2.5 com BCCSP ML-DSA (liboqs).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRYPTO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_ROOT="$(cd "${CRYPTO_ROOT}/.." && pwd)"
FABRIC_SRC="${FABRIC_SRC:-${CRYPTO_ROOT}/.fabric-src}"
OUT_BIN="${OUT_BIN:-${REPO_ROOT}/fabric/mldsa/bin}"
LIBOQS_PREFIX="${LIBOQS_PREFIX:-${CRYPTO_ROOT}/lib}"
FABRIC_VERSION="${FABRIC_VERSION:-v2.5.12}"

export CGO_ENABLED=1
export CGO_CFLAGS="-I${LIBOQS_PREFIX}/include"
export CGO_LDFLAGS="-L${LIBOQS_PREFIX}/lib -loqs -Wl,-rpath,${LIBOQS_PREFIX}/lib"
export LD_LIBRARY_PATH="${LIBOQS_PREFIX}/lib:${LD_LIBRARY_PATH:-}"

if [[ ! -f "${LIBOQS_PREFIX}/lib/liboqs.so" ]] && [[ ! -f "${LIBOQS_PREFIX}/lib64/liboqs.so" ]]; then
  echo "ERRO: liboqs não encontrada em ${LIBOQS_PREFIX}. Rode build-liboqs.sh" >&2
  exit 1
fi

if [[ ! -d "${FABRIC_SRC}/.git" ]]; then
  echo "==> Clonando Fabric ${FABRIC_VERSION}..."
  git clone --depth 1 --branch "${FABRIC_VERSION}" https://github.com/hyperledger/fabric.git "${FABRIC_SRC}"
fi

"${SCRIPT_DIR}/sync-fabric-bccsp.sh"

echo "==> Instalando factory MLDSA..."
cp "${CRYPTO_ROOT}/patches/nopkcs11.go" "${FABRIC_SRC}/bccsp/factory/nopkcs11.go"

mkdir -p "${OUT_BIN}"
echo "==> Compilando peer e orderer (pode levar alguns minutos)..."
cd "${FABRIC_SRC}"
go build -o "${OUT_BIN}/peer" ./cmd/peer
go build -o "${OUT_BIN}/orderer" ./cmd/orderer

echo ""
echo "OK: binários em ${OUT_BIN}"
"${OUT_BIN}/peer" version | head -3 || true
