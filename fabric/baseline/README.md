# Fabric baseline (ECDSA)

Rede **Hyperledger Fabric** permissionada de laboratório — perfil **baseline** (`network=baseline`).

## Pré-requisitos

- Docker + Docker Compose
- Git, curl, Go 1.22+
- ~8 GB disco para `fabric-samples` (clone local)

## Setup rápido

```bash
cd fabric/baseline

# 1. Opcional: copiar e editar .env
cp .env.example .env

# 2. Clonar fabric-samples + binários (uma vez)
./scripts/bootstrap-samples.sh

# 3. Subir rede e canal iomtchannel
./scripts/network-up.sh

# 4. Deploy chaincode iomt
./scripts/deploy-chaincode.sh

# 5. Teste invoke/query
./scripts/test-chaincode.sh

# 6. Health check
./scripts/health-check.sh
```

## Encerrar rede

```bash
./scripts/network-down.sh
```

## Chaincode `iomt`

| Função | Descrição |
|--------|-----------|
| `RegisterObservation` | Grava observação IoMT (id, deviceId, payloadHash, recordedAt) |
| `ReadObservation` | Consulta por id |

Código: `chaincode/iomt/`

## Variáveis

Ver `.env.example`: `FABRIC_SAMPLES_DIR`, `CHANNEL_NAME`, `CHAINCODE_NAME`.

## Raspberry Pi

Cliente em `edge/raspberry-pi/` — cenário **C1**.  
Requer connection profile exportado do test-network (ver README do Pi).

## Versões

- Fabric: **2.5.12** (padrão do bootstrap)
- Canal: `iomtchannel`
