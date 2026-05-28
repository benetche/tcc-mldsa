# Rede Fabric — ML-DSA (Pilar 2)

Espelho de `fabric/baseline/` com peers **`tcc/fabric-peer-mldsa`** (liboqs + BCCSP ML-DSA).

> Não rode **baseline** e **mldsa** ao mesmo tempo (mesmas portas).

## Pré-requisitos

1. `../../crypto/scripts/build-liboqs.sh`
2. `../../crypto/scripts/build-fabric-mldsa.sh` → `fabric/mldsa/bin/peer`
3. `./scripts/build-peer-image.sh` → imagem Docker `tcc/fabric-peer-mldsa:2.5.12`
4. Docker, `fabric-samples`, jq (`./scripts/ensure-jq.sh`)

## Setup completo

```bash
cd fabric/mldsa

# 1. liboqs + binários + imagem peer
../../crypto/scripts/build-liboqs.sh
../../crypto/scripts/build-fabric-mldsa.sh
./scripts/build-peer-image.sh

# 2. Rede (sobe test-network + troca peers para imagem ML-DSA)
./scripts/network-up.sh

# 3. Chaincode
./scripts/deploy-chaincode.sh
./scripts/test-chaincode.sh
./scripts/verify-peer-mldsa.sh
```

## Imagem peer custom

| Item | Valor |
|------|--------|
| Imagem | `tcc/fabric-peer-mldsa:2.5.12` |
| liboqs | em `/usr/local/lib/oqs` |
| BCCSP | factory `MLDSA` no binário; `core.yaml` com seção `MLDSA` |
| CCAAS | `/opt/hyperledger/ccaas_builder` + `docker.io` |
| MSP/TLS | ainda **ECDSA** (Fabric CA) — chaves lab em `lab-msp/` |

```bash
./scripts/build-peer-image.sh      # build imagem
./scripts/switch-peers-mldsa.sh    # recria só os peers (rede já up)
./scripts/verify-peer-mldsa.sh     # confirma liboqs linkada
```

## MSP ML-DSA (laboratório)

```bash
./scripts/configure-msp-mldsa.sh
# → fabric/mldsa/lab-msp/ (formato liboqs, não X.509)
```

Integração MSP X.509 + assinatura de transação peer com ML-DSA: evolução futura (imagem + identidade).

## Cenário C2 (Pi)

```bash
cd ../../edge/raspberry-pi
./scripts/deploy-to-pi.sh   # smoke-c2.sh se FABRIC_NETWORK=mldsa
```

## Encerrar

```bash
./scripts/network-down.sh
```
