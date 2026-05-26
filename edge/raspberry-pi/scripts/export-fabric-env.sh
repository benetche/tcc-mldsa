#!/usr/bin/env bash
# Exporta variáveis Fabric a partir do test-network (User1@org1).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
FABRIC_SAMPLES_DIR="${FABRIC_SAMPLES_DIR:-${REPO_ROOT}/fabric-samples}"
TN="${FABRIC_SAMPLES_DIR}/test-network"
ORG_DIR="${TN}/organizations/peerOrganizations/org1.example.com"

if [[ ! -d "${TN}" ]]; then
  echo "ERRO: test-network não encontrado em ${TN}" >&2
  echo "Execute fabric/baseline/scripts/bootstrap-samples.sh e network-up.sh" >&2
  exit 1
fi

KEY_FILE="$(find "${ORG_DIR}/users/User1@org1.example.com/msp/keystore" -name '*_sk' | head -1)"
CERT_FILE="${ORG_DIR}/users/User1@org1.example.com/msp/signcerts/cert.pem"
TLS_CERT="${ORG_DIR}/peers/peer0.org1.example.com/tls/ca.crt"

export REPO_ROOT
export PATH="${FABRIC_SAMPLES_DIR}/bin:${PATH}"

export FABRIC_MSP_ID=Org1MSP
export FABRIC_MSP_DIR="${ORG_DIR}/users/User1@org1.example.com/msp"
export FABRIC_CHANNEL="${FABRIC_CHANNEL:-iomtchannel}"
export FABRIC_CHAINCODE="${FABRIC_CHAINCODE:-iomt}"
export FABRIC_PEER_ENDPOINT="${FABRIC_PEER_ENDPOINT:-localhost:7051}"
export FABRIC_GATEWAY_HOST="${FABRIC_GATEWAY_HOST:-peer0.org1.example.com}"
export FABRIC_TLS_CERT_PATH="${TLS_CERT}"
export FABRIC_CERT_PATH="${CERT_FILE}"
export FABRIC_KEY_PATH="${KEY_FILE}"
export IOMT_DEVICE_ID="${IOMT_DEVICE_ID:-pi-lab-001}"

echo "FABRIC_PEER_ENDPOINT=${FABRIC_PEER_ENDPOINT}"
echo "FABRIC_CERT_PATH=${FABRIC_CERT_PATH}"
echo "FABRIC_KEY_PATH=${FABRIC_KEY_PATH}"
