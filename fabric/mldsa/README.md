# Rede Fabric — ML-DSA (Pilar 2)

Espelho de `fabric/baseline/` com BCCSP **ML-DSA-65** via liboqs.

> **Não rode baseline e mldsa ao mesmo tempo** — ambos usam as mesmas portas do `test-network`.

## Pré-requisitos

1. `crypto/scripts/build-liboqs.sh`
2. `crypto/scripts/build-fabric-mldsa.sh` (peer/orderer custom em `fabric/mldsa/bin/`)
3. Mesmos pré-requisitos do baseline (Docker, fabric-samples)

## Setup

```bash
# 1. liboqs + binários Fabric ML-DSA
../../crypto/scripts/build-liboqs.sh
../../crypto/scripts/build-fabric-mldsa.sh

cd fabric/mldsa
cp .env.example .env

# 2. fabric-samples (compartilhado com baseline)
./scripts/bootstrap-samples.sh

# 3. Rede (logs network=mldsa)
./scripts/network-up.sh
./scripts/deploy-chaincode.sh
./scripts/test-chaincode.sh
```

## BCCSP

Copie `../../crypto/bccsp.yaml.example` para o MSP ou defina no peer:

```yaml
BCCSP:
  Default: MLDSA
  MLDSA:
    FileKeyStore:
      KeyStorePath: /var/hyperledger/msp/keystore
```

Integração MSP X.509 completa: em evolução (task 06). Primitivas validadas em `crypto/bccsp/fabric`.

## Cenário C2 (Pi)

Após rede estável:

```bash
cd edge/raspberry-pi
# FABRIC_NETWORK=mldsa no deploy (futuro: smoke-c2.sh)
```

## Encerrar

```bash
./scripts/network-down.sh
```
