# Raspberry Pi 4 — cliente IoMT (C1 / C2)

Dispositivo de borda que submete observações ao chaincode **`iomt`** nas redes Fabric **baseline** (C1) e **mldsa** (C2), com assinatura criptográfica na borda gravada on-chain.

## Documentação principal

**[docs/FLUXO-CENARIOS-PI.md](docs/FLUXO-CENARIOS-PI.md)** — fluxo completo: pré-requisitos, deploy, execução de cada cenário no Pi, variáveis, troubleshooting.

## Cenários no Pi

| ID | Rede | Assinatura borda | Smoke |
|----|------|------------------|-------|
| **C1** | `fabric/baseline` | ECDSA-P256 | `./scripts/smoke-c1.sh` |
| **C2** | `fabric/mldsa` | ML-DSA-65 (liboqs) | `./scripts/smoke-c2.sh` |
| C3/C4 | ESP32 | — | Ver `edge/esp32/README.md` |

## Início rápido (deploy do PC)

```bash
cp lab.env.example lab.env   # PI_HOST, senha, LAB_FABRIC_HOST, FABRIC_NETWORK
cd edge/raspberry-pi

# C2 (mldsa) — padrão
./scripts/deploy-to-pi.sh

# C1 (baseline): subir fabric/baseline no PC, lab.env FABRIC_NETWORK=baseline, depois deploy
```

No Pi após deploy:

```bash
cd ~/tcc-iomt/edge/raspberry-pi && source config.env && ./scripts/smoke-c2.sh
```

Contexto de laboratório: [.cursor/context/laboratorio-pi.md](../../.cursor/context/laboratorio-pi.md).

## Build local (dev)

```bash
go build -o bin/submit-observation ./cmd/submit-observation/
```

## Métricas

```bash
./scripts/collect_metrics.sh 30 1 /tmp/metrics.csv
```
