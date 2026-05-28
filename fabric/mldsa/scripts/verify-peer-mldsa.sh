#!/usr/bin/env bash
# Verifica peers com binário customizado e liboqs no container.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_TAG="${MLDSA_PEER_IMAGE:-tcc/fabric-peer-mldsa:2.5.12}"

for peer in peer0.org1.example.com peer0.org2.example.com; do
  if ! docker ps --format '{{.Names}}' | grep -qx "${peer}"; then
    echo "ERRO: container ${peer} não está rodando" >&2
    exit 1
  fi
  echo "==> ${peer}"
  img="$(docker inspect "${peer}" --format '{{.Config.Image}}')"
  echo "    image: ${img}"
  if [[ "${img}" != "${IMAGE_TAG}" ]]; then
    echo "AVISO: imagem diferente de ${IMAGE_TAG}" >&2
  fi
  docker exec "${peer}" peer version 2>&1 | head -2 | sed 's/^/    /'
  if docker exec "${peer}" sh -c 'ldd /usr/local/bin/peer 2>/dev/null | grep -q liboqs'; then
    echo "    liboqs: linkada OK"
  else
    echo "    liboqs: não detectada em ldd (verifique LD_LIBRARY_PATH)" >&2
  fi
done

echo "[network=mldsa] verify-peer-mldsa OK"
