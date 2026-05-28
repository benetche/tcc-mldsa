#!/usr/bin/env bash
# Instala jq em fabric/mldsa/bin/ se não existir no sistema.
set -euo pipefail
MLDSA_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
JQ_BIN="${MLDSA_ROOT}/bin/jq"

if command -v jq &>/dev/null; then
  exit 0
fi

if [[ -x "${JQ_BIN}" ]]; then
  exit 0
fi

mkdir -p "${MLDSA_ROOT}/bin"
ARCH="$(uname -m)"
case "${ARCH}" in
  x86_64) JQ_URL="https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-linux-amd64" ;;
  aarch64|arm64) JQ_URL="https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-linux-arm64" ;;
  *)
    echo "ERRO: arquitetura ${ARCH} não suportada; instale jq: sudo apt install jq" >&2
    exit 1
    ;;
esac

echo "Baixando jq para ${JQ_BIN}..."
curl -fsSL -o "${JQ_BIN}" "${JQ_URL}"
chmod +x "${JQ_BIN}"
echo "OK: jq $( "${JQ_BIN}" --version )"
