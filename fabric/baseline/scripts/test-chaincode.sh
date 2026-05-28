#!/usr/bin/env bash
# Invoke/query de teste no chaincode iomt via peer CLI.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

require_fabric_samples
TN="$(test_network_dir)"
export PATH="${FABRIC_SAMPLES_DIR}/bin:${PATH}"
export FABRIC_CFG_PATH="${TN}/../config/"

ENV_FILE="${TN}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp"
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID=Org1MSP
export CORE_PEER_TLS_ROOTCERT_FILE="${TN}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt"
export CORE_PEER_MSPCONFIGPATH="${ENV_FILE}"
export CORE_PEER_ADDRESS=localhost:7051

TEST_ID="obs-$(date +%s)"
DEVICE="pi-lab-001"
HASH="sha256:fixture-deadbeef"
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

echo "[network=baseline] RegisterObservation ${TEST_ID}..."
peer chaincode invoke \
  -o localhost:7050 \
  --ordererTLSHostnameOverride orderer.example.com \
  --tls \
  --cafile "${TN}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem" \
  -C "${CHANNEL_NAME}" \
  -n "${CHAINCODE_NAME}" \
  --peerAddresses localhost:7051 \
  --tlsRootCertFiles "${TN}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" \
  --peerAddresses localhost:9051 \
  --tlsRootCertFiles "${TN}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt" \
  -c "{\"function\":\"RegisterObservation\",\"Args\":[\"${TEST_ID}\",\"${DEVICE}\",\"${HASH}\",\"${TS}\",\"\",\"\",\"\",\"\"]}"

sleep 3
echo "[network=baseline] ReadObservation..."
peer chaincode query \
  -C "${CHANNEL_NAME}" \
  -n "${CHAINCODE_NAME}" \
  -c "{\"function\":\"ReadObservation\",\"Args\":[\"${TEST_ID}\"]}"

echo "OK: transação de teste concluída (id=${TEST_ID})"
