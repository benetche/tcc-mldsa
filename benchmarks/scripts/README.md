# Scripts de benchmark (Pilar 4)

Suíte **C1–C4** × `hospital-low` / `hospital-high` com paridade experimental.
Reaproveita a ingestão FHIR (`scripts/ingestion`, `iomt_fhir`).

Estado da coleta: [docs/estado-do-projeto.md](../../docs/estado-do-projeto.md) · Relatório: [relatorio-pqc-iomt.md](../reports/relatorio-pqc-iomt.md).

## Componentes

| Script | Papel |
|--------|-------|
| `run_suite.sh` | Orquestra a matriz (cenários × cargas) |
| `bench_lib.py` | Executa **1 cenário × 1 carga**; mede latência/TPS/recursos |
| `analyze.py` | Agrega `results/`, gera tabelas e gráficos em `reports/` |
| `validate-p3-ingestao.sh` | Smoke da ingestão P3 (pré-requisito) |
| `validate-p2-scenarios.sh` | Validação cripto/MSP P2 |

## Uso

```bash
# Suíte completa
./run_suite.sh --all

# Cenário único, série robusta (≥30 amostras + warmup)
./run_suite.sh --scenario C1 --samples 30 --warmup 10

# Carga específica
./run_suite.sh --scenario C1 --load hospital-high

# Dry-run (sem rede; valida orquestração e stubs ESP32)
./run_suite.sh --all --dry-run

# Análise
python3 analyze.py --glob '*'
```

## Saída por execução

```
benchmarks/results/<timestamp>-Cx-load/
  metadata.json   # cenário, signing_mode, commit, versões, resumo
  metrics.csv     # 1 linha por transação medida
  resources.csv   # amostras CPU%/RAM
```

Dados brutos em `results/` são **gitignored**. Sem hardware ESP32, o runner
registra `hardware_pending` (cenário não omitido na orquestração).

## ESP32 (C3/C4)

Sem hardware: `hardware_pending`. Com hardware, definir bridge:

```bash
export IOMT_ESP32_BRIDGE=mqtt   # mqtt | serial | http (a implementar no edge)
```

Ver [cenarios-experimentais.md](../../docs/cenarios-experimentais.md).
