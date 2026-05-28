#!/usr/bin/env bash
# Compila liboqs + sign-payload para linux/arm64 (Pi) via Docker QEMU — sem gcc cross no host.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRYPTO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_ROOT="$(cd "${CRYPTO_ROOT}/.." && pwd)"
OUT_BIN="${REPO_ROOT}/edge/raspberry-pi/bin/sign-payload-mldsa"
LIB_PI="${CRYPTO_ROOT}/lib-pi-arm64"

command -v docker >/dev/null || { echo "docker obrigatório" >&2; exit 1; }

mkdir -p "$(dirname "${OUT_BIN}")" "${LIB_PI}"

echo "==> Build ARM64 em container (pode levar alguns minutos)..."
docker run --rm --platform linux/arm64 \
  -v "${CRYPTO_ROOT}:/crypto:rw" \
  -w /crypto \
  golang:1.22-bookworm \
  bash -c '
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq cmake ninja-build git pkg-config build-essential libssl-dev >/dev/null
export LIBOQS_PREFIX=/crypto/lib-pi-arm64
export CGO_ENABLED=1
if [[ ! -f "${LIBOQS_PREFIX}/lib/pkgconfig/liboqs.pc" ]]; then
  ./scripts/build-liboqs.sh
fi
export PKG_CONFIG_PATH="${LIBOQS_PREFIX}/lib/pkgconfig"
export LD_LIBRARY_PATH="${LIBOQS_PREFIX}/lib:${LD_LIBRARY_PATH:-}"
go build -o /crypto/out-sign-payload ./cmd/sign-payload/
'

mv "${CRYPTO_ROOT}/out-sign-payload" "${OUT_BIN}"
chmod +x "${OUT_BIN}"
echo "OK: ${OUT_BIN}"
echo "OK: libs em ${LIB_PI}/lib/"
