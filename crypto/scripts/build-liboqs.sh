#!/usr/bin/env bash
# Compila liboqs (ML-DSA-65) para uso via CGO no pacote crypto/oqs.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRYPTO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
INSTALL_PREFIX="${LIBOQS_PREFIX:-${CRYPTO_ROOT}/lib}"
SRC_DIR="${CRYPTO_ROOT}/.liboqs-src"
LIBOQS_VERSION="${LIBOQS_VERSION:-0.12.0}"
LIBOQS_REPO="${LIBOQS_REPO:-https://github.com/open-quantum-safe/liboqs.git}"

JOBS="${JOBS:-$(nproc 2>/dev/null || echo 4)}"

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "ERRO: '$1' não encontrado. Instale build-essential, cmake, git, ninja-build." >&2
    exit 1
  }
}

need_cmd git
need_cmd cmake

OPENSSL_CMAKE=()
if pkg-config --exists openssl 2>/dev/null || [[ -f /usr/include/openssl/ssl.h ]]; then
  OPENSSL_CMAKE=(-DOQS_USE_OPENSSL=ON)
else
  echo "AVISO: libssl-dev ausente — compilando com -DOQS_USE_OPENSSL=OFF" >&2
  OPENSSL_CMAKE=(-DOQS_USE_OPENSSL=OFF)
fi

if ! command -v ninja >/dev/null 2>&1; then
  echo "AVISO: ninja não encontrado; usando gerador Unix Makefiles (mais lento)." >&2
  CMAKE_GENERATOR=(-G "Unix Makefiles")
else
  CMAKE_GENERATOR=(-G Ninja)
fi

if [[ ! -d "${SRC_DIR}/.git" ]]; then
  echo "==> Clonando liboqs ${LIBOQS_VERSION}..."
  rm -rf "${SRC_DIR}"
  git clone --depth 1 --branch "${LIBOQS_VERSION}" "${LIBOQS_REPO}" "${SRC_DIR}"
fi

BUILD_DIR="${SRC_DIR}/build"
mkdir -p "${BUILD_DIR}"

echo "==> Configurando liboqs (install: ${INSTALL_PREFIX})..."
cmake -S "${SRC_DIR}" -B "${BUILD_DIR}" \
  "${CMAKE_GENERATOR[@]}" \
  -DCMAKE_INSTALL_PREFIX="${INSTALL_PREFIX}" \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=ON \
  -DOQS_BUILD_ONLY_LIB=ON \
  -DOQS_ENABLE_SIG_ml_dsa_65=ON \
  -DOQS_ENABLE_SIG_ml_dsa_44=OFF \
  -DOQS_ENABLE_SIG_ml_dsa_87=OFF \
  -DOQS_DIST_BUILD=ON \
  "${OPENSSL_CMAKE[@]}"

echo "==> Compilando (jobs=${JOBS})..."
cmake --build "${BUILD_DIR}" --parallel "${JOBS}"

echo "==> Instalando em ${INSTALL_PREFIX}..."
cmake --install "${BUILD_DIR}"

echo ""
echo "OK: liboqs instalada."
echo "    export LIBOQS_PREFIX=${INSTALL_PREFIX}"
echo "    export PKG_CONFIG_PATH=${INSTALL_PREFIX}/lib/pkgconfig:\${PKG_CONFIG_PATH}"
echo "    export LD_LIBRARY_PATH=${INSTALL_PREFIX}/lib:\${LD_LIBRARY_PATH}"
echo ""
echo "Testes: cd crypto && ./scripts/test-mldsa.sh"
