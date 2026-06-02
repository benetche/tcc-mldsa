# Cenários de benchmark — C1 a C4

Definições YAML da matriz **2×2** (rede × dispositivo). Cada cenário executa as cargas **`hospital-low`** e **`hospital-high`**.

Estado da coleta: [docs/estado-do-projeto.md](../../docs/estado-do-projeto.md).

## Identificadores

| Arquivo | Cenário | Rede | Dispositivo |
|---------|---------|------|-------------|
| `c1-pi-baseline.yaml` | C1 | ECDSA | Raspberry Pi 4 |
| `c2-pi-mldsa.yaml` | C2 | ML-DSA | Raspberry Pi 4 |
| `c3-esp32-baseline.yaml` | C3 | ECDSA | ESP32-D |
| `c4-esp32-mldsa.yaml` | C4 | ML-DSA | ESP32-D |

## Cargas hospitalares

| Arquivo | Perfil |
|---------|--------|
| `hospital-low.yaml` | Baixa frequência — smoke e paridade |
| `hospital-high.yaml` | Alta frequência — estresse IoMT |

## Campos do YAML (referência)

```yaml
scenario_id: C1
network: baseline          # baseline | mldsa
device: raspberry-pi       # raspberry-pi | esp32
signing_mode: pi_client    # pi_client | esp32_direct | esp32_payload_only
load_profile: hospital-low
duration_minutes: 10
target_tps: 5
warmup_transactions: 50
repetitions: 30
```

## Execução

```bash
# Suíte completa
./benchmarks/scripts/run_suite.sh --all

# Cenário e carga isolados
./benchmarks/scripts/run_suite.sh --scenario C3 --load hospital-high

# Pi remoto
./benchmarks/scripts/run_suite_pi.sh --deploy C1 hospital-low --samples 30
```

## Saída (gitignored)

```
benchmarks/results/<run_id>/
  metadata.json
  metrics.csv
  resources.csv
```

Análise: `python3 benchmarks/scripts/analyze.py --glob '*'`
