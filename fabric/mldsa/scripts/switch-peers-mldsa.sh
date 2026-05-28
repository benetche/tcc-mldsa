#!/usr/bin/env bash
# Recria containers peer com imagem ML-DSA (mantém volumes/MSP ECDSA do test-network).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

MLDSA_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_ROOT="$(cd "${MLDSA_ROOT}/../.." && pwd)"
TN="$(test_network_dir)"
IMAGE_TAG="${MLDSA_PEER_IMAGE:-tcc/fabric-peer-mldsa:2.5.12}"

export MLDSA_PEER_CORE_CFG="${MLDSA_ROOT}/config/core.yaml"
export DOCKER_SOCK="${DOCKER_SOCK:-/var/run/docker.sock}"

"${SCRIPT_DIR}/build-peer-image.sh"

if ! docker ps --format '{{.Names}}' | grep -q '^peer0.org1.example.com$'; then
  echo "ERRO: rede não está no ar. Execute ./scripts/network-up.sh primeiro." >&2
  exit 1
fi

cd "${TN}"
CONTAINER_CLI="${CONTAINER_CLI:-docker}"
COMPOSE_FILES="-f compose/compose-test-net.yaml -f compose/${CONTAINER_CLI}/${CONTAINER_CLI}-compose-test-net.yaml"
COMPOSE_FILES="${COMPOSE_FILES} -f ${MLDSA_ROOT}/compose/docker-compose.mldsa.yaml"

echo "[network=mldsa] Recriando peers com ${IMAGE_TAG}..."
DOCKER_SOCK="${DOCKER_SOCK}" ${CONTAINER_CLI} compose ${COMPOSE_FILES} up -d \
  --force-recreate --no-deps peer0.org1.example.com peer0.org2.example.com

sleep 3
"${SCRIPT_DIR}/verify-peer-mldsa.sh"
