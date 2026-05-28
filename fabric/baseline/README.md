# Fabric baseline (ECDSA)

Rede **Hyperledger Fabric** permissionada de laboratório — perfil **baseline** (`network=baseline`).

## Pré-requisitos

- Docker + Docker Compose
- Git, curl, Go 1.22+
- **jq** — `sudo apt install jq` ou `./scripts/ensure-jq.sh` (baixa em `bin/`)
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

# 4. Deploy chaincode iomt (CCAAS — evita docker build dentro do peer)
./scripts/deploy-chaincode.sh
# Modo clássico (pode falhar com "broken pipe" no Docker): DEPLOY_MODE=legacy ./scripts/deploy-chaincode.sh

# 5. Teste invoke/query
./scripts/test-chaincode.sh

# 6. Health check
./scripts/health-check.sh
```

## Redeploy do chaincode

Se `iomt` já foi commitado (sequence 1), um novo `./scripts/deploy-chaincode.sh` usa **sequence 2** automaticamente (`CC_SEQUENCE=auto`).

Erro típico se forçar sequence antiga:
`requested sequence is 1, but new definition must be sequence 2`

Para primeiro deploy apenas: `CC_SEQUENCE=1 ./scripts/deploy-chaincode.sh`

Se o chaincode **já funciona**, não é necessário redeploy — use `./scripts/test-chaincode.sh`.

## Encerrar rede

```bash
./scripts/network-down.sh
```

## Chaincode `iomt`

| Função | Descrição |
|--------|-----------|
| `RegisterObservation` | Grava observação IoMT (+ signAlg, deviceSignature opcionais na borda) |
| `ReadObservation` | Consulta por id |

Código: `chaincode/iomt/`

## Variáveis

Ver `.env.example`: `FABRIC_SAMPLES_DIR`, `CHANNEL_NAME`, `CHAINCODE_NAME`.

## Raspberry Pi

Cliente em `edge/raspberry-pi/` — cenário **C1** (`./scripts/smoke-c1.sh`).  
Modo padrão: **peer-cli** (dois endossos). Opcional: Fabric Gateway (`IOMT_SUBMIT_MODE=gateway` + `/etc/hosts` via `setup-hosts.sh`).

## Versões

- Fabric: **2.5.12** (padrão do bootstrap)
- Canal: `iomtchannel`
