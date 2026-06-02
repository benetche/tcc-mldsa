# Cloud Agents — TCC ML-DSA + Fabric + IoMT

Instruções para agentes Cursor em ambiente cloud/ephemeral. A pasta `.cursor/` é **gitignored** (uso local); siga a documentação versionada em `docs/`.

## Projeto

Blockchain permissionada **Hyperledger Fabric** com assinaturas **ML-DSA (Dilithium)** via **liboqs/BCCSP**, ingestão **MIMIC-IV/FHIR** para **IoMT**, benchmarks **ECDSA vs ML-DSA**.

## Setup mínimo (quando código existir)

```bash
# Dependências comuns (ajustar versões conforme docs/decisoes-stack.md)
sudo apt-get update && sudo apt-get install -y docker.io docker-compose-plugin git golang-go python3 python3-pip

# Fabric baseline (exemplo — ver fabric/baseline/README.md)
cd fabric/baseline && ./network.sh up createChannel
```

## Variáveis de ambiente (placeholders — nunca valores reais)

```bash
export MIMIC_DATA_PATH=/path/to/local/mimic  # fora do git
export PHYSIONET_USER=placeholder
export PHYSIONET_PASSWORD=placeholder
export FABRIC_NETWORK=baseline  # ou mldsa
```

## Estrutura

| Pasta | Conteúdo |
|-------|----------|
| `fabric/` | Redes baseline e ML-DSA |
| `crypto/` | liboqs, BCCSP |
| `health-data/` | Mappings MIMIC, fixtures FHIR |
| `edge/` | Raspberry Pi, ESP32 |
| `benchmarks/` | Scripts e relatórios |
| `monitoring/` | P5 opcional: Prometheus, Grafana, Telegraf |
| `docs/` | Cenários, paridade, laboratório, decisões de stack |

## Ordem de trabalho

1. [docs/decisoes-stack.md](docs/decisoes-stack.md) e [docs/cenarios-experimentais.md](docs/cenarios-experimentais.md)
2. Checklist da fase em `.cursor/tasks/` (apenas local, se existir)
3. Laboratório: [docs/laboratorio-local.md](docs/laboratorio-local.md) — nunca commitar `lab.env` / `secrets.h`

## Segurança

- Rede de laboratório isolada
- Sem chaves reais, MIMIC bruto ou credenciais no repositório
- Resultados volumosos em `benchmarks/results/` (gitignored)
