# Cloud Agents — TCC ML-DSA + Fabric + IoMT

Instruções para agentes Cursor em ambiente cloud/ephemeral. Convenções de código: `.cursor/rules/`.

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
| `.cursor/tasks/` | Checklists por fase |

## Ordem de trabalho

1. Task atual em `.cursor/tasks/README.md`
2. Agente do pilar em `.cursor/agents/`
3. Atualizar `.cursor/roadmap/ROADMAP.md#registro-de-progresso`

## Segurança

- Rede de laboratório isolada
- Sem chaves reais, MIMIC bruto ou credenciais no repositório
- Resultados volumosos em `benchmarks/results/` (gitignored)
