#!/usr/bin/env bash
# Executado no Pi via SSH: compila liboqs (ARM64 nativo) + sign-payload-mldsa.
set -euo pipefail
REMOTE_BASE="${1:?REMOTE_BASE obrigatório}"
CRYPTO="${REMOTE_BASE}/crypto"
BIN="${REMOTE_BASE}/bin/sign-payload-mldsa"

export LIBOQS_PREFIX="${CRYPTO}/lib"
export PKG_CONFIG_PATH="${LIBOQS_PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
export LD_LIBRARY_PATH="${LIBOQS_PREFIX}/lib:${LD_LIBRARY_PATH:-}"
export CGO_ENABLED=1

cd "${CRYPTO}"
if [[ ! -f "${LIBOQS_PREFIX}/lib/pkgconfig/liboqs.pc" ]]; then
  echo "==> [Pi] Compilando liboqs (primeira vez, ~5–15 min)..."
  ./scripts/build-liboqs.sh
else
  echo "==> [Pi] liboqs já instalada em ${LIBOQS_PREFIX}"
fi

mkdir -p "$(dirname "${BIN}")"
echo "==> [Pi] Compilando sign-payload-mldsa..."
go build -o "${BIN}" ./cmd/sign-payload/
chmod +x "${BIN}"
file "${BIN}"
"${BIN}" -keydir "${REMOTE_BASE}/edge/raspberry-pi/keys/mldsa-65" -message "sha256:pi-build-test" | head -c 120
echo ""
echo "OK: ${BIN}"
