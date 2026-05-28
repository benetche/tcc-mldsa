#!/usr/bin/env bash
# Copia adaptador ML-DSA para o tree do Hyperledger Fabric (v2.5.12).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRYPTO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_ROOT="$(cd "${CRYPTO_ROOT}/.." && pwd)"
FABRIC_SRC="${FABRIC_SRC:-${CRYPTO_ROOT}/.fabric-src}"
DEST="${FABRIC_SRC}/bccsp/mldsa"

if [[ ! -d "${FABRIC_SRC}/.git" ]]; then
  echo "ERRO: clone Fabric em ${FABRIC_SRC} (v2.5.12)" >&2
  exit 1
fi

echo "==> Sincronizando bccsp/mldsa em ${DEST}..."
rm -rf "${DEST}"
mkdir -p "${DEST}/oqs"

cp "${CRYPTO_ROOT}/oqs/mldsa.go" "${DEST}/oqs/mldsa.go"

for f in opts.go keys.go keygen.go bccsp.go; do
  sed \
    -e 's/package fabric/package mldsa/g' \
    -e 's|github.com/beneti/tcc-projeto-mldsa/crypto/oqs|github.com/hyperledger/fabric/bccsp/mldsa/oqs|g' \
    -e 's|github.com/hyperledger/fabric-lib-go/bccsp|github.com/hyperledger/fabric/bccsp|g' \
    -e 's|github.com/hyperledger/fabric-lib-go/bccsp/sw|github.com/hyperledger/fabric/bccsp/sw|g' \
    "${CRYPTO_ROOT}/bccsp/fabric/${f}" > "${DEST}/${f}"
done

cp "${CRYPTO_ROOT}/integration/mldsafactory.go" "${FABRIC_SRC}/bccsp/factory/mldsafactory.go"

echo "OK: pacotes em ${DEST}"
