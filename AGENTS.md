# Instruções para agentes (Cursor / cloud)

Repositório do TCC **ML-DSA + Hyperledger Fabric + IoMT**. Documentação versionada em `docs/`; pasta `.cursor/` é **gitignored** (uso local).

## Contexto obrigatório

1. [docs/estado-do-projeto.md](docs/estado-do-projeto.md) — status por pilar e C1–C4
2. [docs/decisoes-stack.md](docs/decisoes-stack.md) — stack e limitações PQC
3. [docs/cenarios-experimentais.md](docs/cenarios-experimentais.md) — matriz e hipóteses
4. [docs/paridade-experimental.md](docs/paridade-experimental.md) — regras de benchmark

## Setup mínimo

```bash
sudo apt-get update && sudo apt-get install -y docker.io docker-compose-plugin git golang-go python3 python3-pip
cd fabric/baseline && ./scripts/bootstrap-samples.sh && ./scripts/network-up.sh
```

## Variáveis (placeholders — nunca valores reais no git)

```bash
export MIMIC_DATA_PATH=/path/to/local/mimic
export PHYSIONET_USER=placeholder
export PHYSIONET_PASSWORD=placeholder
export FABRIC_NETWORK=baseline   # ou mldsa
export MQTT_HOST=<IP_DO_BROKER>  # scripts ESP32
```

## Estrutura

| Pasta | Conteúdo |
|-------|----------|
| `fabric/` | Redes baseline e mldsa |
| `crypto/` | liboqs, BCCSP |
| `health-data/`, `scripts/ingestion/` | FHIR, cargas hospitalares |
| `edge/` | Pi (C1/C2), ESP32 (C3/C4) |
| `benchmarks/` | Suíte e relatórios |
| `monitoring/` | P5 opcional |
| `docs/` | Documentação de referência |

## Segurança

- Rede de laboratório isolada
- Não commitar: `lab.env`, `secrets.h`, `sdkconfig`, MIMIC bruto, `benchmarks/results/`, `*.pem` de MSP
- Matriz **C1–C4** obrigatória; paridade experimental entre baseline e mldsa

## Ordem de trabalho sugerida

1. Ler estado em `docs/estado-do-projeto.md`
2. Tarefas locais em `.cursor/tasks/` (se existir na máquina do desenvolvedor)
3. Atualizar documentação em `docs/` e READMEs de módulo após mudanças relevantes
