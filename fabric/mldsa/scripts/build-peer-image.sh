#!/usr/bin/env bash
# Imagem Docker peer/orderer com binários ML-DSA + liboqs.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MLDSA_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_ROOT="$(cd "${MLDSA_ROOT}/../.." && pwd)"
IMAGE_TAG="${MLDSA_PEER_IMAGE:-tcc/fabric-peer-mldsa:2.5.12}"
LIBOQS_PREFIX="${LIBOQS_PREFIX:-${REPO_ROOT}/crypto/lib}"
PEER_BIN="${MLDSA_ROOT}/bin/peer"
ORDERER_BIN="${MLDSA_ROOT}/bin/orderer"

if [[ ! -f "${LIBOQS_PREFIX}/lib/liboqs.so" ]] && [[ ! -f "${LIBOQS_PREFIX}/lib/liboqs.so.0.12.0" ]]; then
  echo "ERRO: liboqs em ${LIBOQS_PREFIX}/lib — rode crypto/scripts/build-liboqs.sh" >&2
  exit 1
fi

if [[ ! -x "${PEER_BIN}" ]]; then
  echo "==> Binários Fabric ausentes; compilando..."
  "${REPO_ROOT}/crypto/scripts/build-fabric-mldsa.sh"
fi

DIST="${MLDSA_ROOT}/docker/dist"
rm -rf "${DIST}"
mkdir -p "${DIST}/bin" "${DIST}/lib" "${DIST}/ccaas_builder"

cp -a "${LIBOQS_PREFIX}/lib/." "${DIST}/lib/"
cp "${PEER_BIN}" "${ORDERER_BIN}" "${DIST}/bin/"

echo "==> Extraindo ccaas_builder da imagem hyperledger/fabric-peer:2.5..."
EXTRACT_ID="$(docker create hyperledger/fabric-peer:2.5)"
docker cp "${EXTRACT_ID}:/opt/hyperledger/ccaas_builder/." "${DIST}/ccaas_builder/"
docker rm -f "${EXTRACT_ID}" >/dev/null

echo "==> Build imagem ${IMAGE_TAG}..."
docker build -t "${IMAGE_TAG}" -f "${MLDSA_ROOT}/docker/Dockerfile" "${MLDSA_ROOT}/docker"

echo "OK: ${IMAGE_TAG}"
docker run --rm --entrypoint peer "${IMAGE_TAG}" version 2>&1 | head -3
