#!/usr/bin/env bash
# Cross-compila msp-mldsa-sign para linux/arm64 (Raspberry Pi).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO="$(cd "${ROOT}/.." && pwd)"
OUT="${REPO}/edge/raspberry-pi/bin/msp-mldsa-sign"
LIB="${ROOT}/lib"

export PKG_CONFIG_PATH="${LIB}/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
export CGO_ENABLED=1
export GOOS=linux
export GOARCH=arm64
export CC="${CC:-aarch64-linux-gnu-gcc}"

if ! command -v "${CC}" &>/dev/null; then
  echo "Instale: sudo apt-get install -y gcc-aarch64-linux-gnu" >&2
  exit 1
fi

mkdir -p "$(dirname "${OUT}")"
(cd "${ROOT}" && go build -o "${OUT}" ./cmd/msp-mldsa-sign/)
echo "OK: ${OUT}"
