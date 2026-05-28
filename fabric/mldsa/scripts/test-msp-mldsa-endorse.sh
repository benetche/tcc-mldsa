#!/usr/bin/env bash
# E2E P2: transação Fabric + assinatura MSP ML-DSA (BCCSP) gravada on-chain.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
CRYPTO="${REPO_ROOT}/crypto"
MLDSA_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
MSP_DIR="${MLDSA_ROOT}/lab-msp/org1/user1"
TN="$(test_network_dir)"

export PATH="${FABRIC_SAMPLES_DIR}/bin:${PATH}"
export FABRIC_CFG_PATH="${TN}/../config/"
export LIBOQS_PREFIX="${LIBOQS_PREFIX:-${CRYPTO}/lib}"
export PKG_CONFIG_PATH="${LIBOQS_PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
export LD_LIBRARY_PATH="${LIBOQS_PREFIX}/lib:${LD_LIBRARY_PATH:-}"
export CGO_ENABLED=1

if [[ ! -f "${MSP_DIR}/keystore/priv_mldsa65_sk" ]]; then
  "${REPO_ROOT}/crypto/scripts/gen-msp-mldsa-lab.sh" "${MSP_DIR}"
fi

TEST_ID="msp-$(date +%s)"
DEVICE="pi-lab-001"
HASH="sha256:msp-endorse-fixture"
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

MSP_JSON="$(cd "${CRYPTO}" && go run ./cmd/msp-mldsa-sign/ \
  -mspdir "${MSP_DIR}" \
  -obs-id "${TEST_ID}" \
  -payload-hash "${HASH}" \
  -recorded-at "${TS}")"

MSP_ALG="$(echo "${MSP_JSON}" | python3 -c "import json,sys; print(json.load(sys.stdin)['mspSignAlg'])")"
MSP_SIG="$(echo "${MSP_JSON}" | python3 -c "import json,sys; print(json.load(sys.stdin)['mspSignature'])")"

export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID=Org1MSP
export CORE_PEER_MSPCONFIGPATH="${TN}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp"
export CORE_PEER_TLS_ROOTCERT_FILE="${TN}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt"
export CORE_PEER_ADDRESS=localhost:7051

echo "[network=mldsa] RegisterObservation + MSP ML-DSA (${TEST_ID})..."
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
  -c "{\"function\":\"RegisterObservation\",\"Args\":[\"${TEST_ID}\",\"${DEVICE}\",\"${HASH}\",\"${TS}\",\"\",\"\",\"${MSP_ALG}\",\"${MSP_SIG}\"]}"

sleep 3
LEDGER="$(peer chaincode query -C "${CHANNEL_NAME}" -n "${CHAINCODE_NAME}" \
  -c "{\"function\":\"ReadObservation\",\"Args\":[\"${TEST_ID}\"]}")"

echo "${LEDGER}" | python3 -c "
import json,sys
d=json.load(sys.stdin)
assert d.get('mspSignAlg')=='ML-DSA-65', d
assert d.get('mspSignature'), 'mspSignature ausente'
print('OK: mspSignAlg=%s mspSignatureBytes=%s' % (d['mspSignAlg'], d.get('mspSignatureBytes', len(d['mspSignature']))))
"

echo "[network=mldsa] test-msp-mldsa-endorse OK"
