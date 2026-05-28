#!/usr/bin/env bash
# Cross-compila sign-payload para linux/arm64 (Raspberry Pi) com liboqs.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO="$(cd "${ROOT}/.." && pwd)"
LIB="${ROOT}/lib"
OUT="${REPO}/edge/raspberry-pi/bin/sign-payload-mldsa"

if [[ ! -f "${LIB}/lib/pkgconfig/liboqs.pc" ]]; then
  echo "Execute primeiro: ${ROOT}/scripts/build-liboqs.sh" >&2
  exit 1
fi

export PKG_CONFIG_PATH="${LIB}/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
export CGO_ENABLED=1
export GOOS=linux
export GOARCH=arm64
export CC="${CC:-aarch64-linux-gnu-gcc}"

if ! command -v "${CC}" &>/dev/null; then
  echo "Instale o cross-compiler: sudo apt-get install -y gcc-aarch64-linux-gnu" >&2
  exit 1
fi

mkdir -p "$(dirname "${OUT}")"
(
  cd "${ROOT}"
  go build -o "${OUT}" ./cmd/sign-payload/
)
echo "OK: ${OUT}"
