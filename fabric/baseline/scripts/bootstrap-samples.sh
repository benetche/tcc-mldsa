#!/usr/bin/env bash
# Clona fabric-samples e instala binários Fabric (uma vez por máquina).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

FABRIC_VERSION="${FABRIC_VERSION:-2.5.12}"
CA_VERSION="${CA_VERSION:-1.5.15}"

if [[ -d "$(test_network_dir)" ]]; then
  echo "fabric-samples já presente em ${FABRIC_SAMPLES_DIR}"
  exit 0
fi

mkdir -p "$(dirname "${FABRIC_SAMPLES_DIR}")"
git clone --depth 1 https://github.com/hyperledger/fabric-samples.git "${FABRIC_SAMPLES_DIR}"

cd "${FABRIC_SAMPLES_DIR}"
curl -sSL https://bit.ly/2ysbOFE | bash -s -- "${FABRIC_VERSION}" "${CA_VERSION}"

echo "OK: fabric-samples em ${FABRIC_SAMPLES_DIR}"
