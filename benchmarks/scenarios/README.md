# Cenários de benchmark — C1 a C4

Todos os cenários da matriz **2×2** (rede × dispositivo) são **obrigatórios** para robustez do TCC.

## Identificadores

| Arquivo | Cenário | Rede | Dispositivo |
|---------|---------|------|-------------|
| `c1-pi-baseline.yaml` | C1 | ECDSA | Raspberry Pi 4 |
| `c2-pi-mldsa.yaml` | C2 | ML-DSA | Raspberry Pi 4 |
| `c3-esp32-baseline.yaml` | C3 | ECDSA | ESP32-D |
| `c4-esp32-mldsa.yaml` | C4 | ML-DSA | ESP32-D |

## Cargas hospitalares

| Arquivo | Perfil | Uso |
|---------|--------|-----|
| `hospital-low.yaml` | Baixa frequência | Smoke + paridade |
| `hospital-high.yaml` | Alta frequência | Estresse IoMT |

Cada cenário C1–C4 deve executar **ambas** as cargas.

## Campos esperados no YAML (template)

```yaml
scenario_id: C1
network: baseline          # baseline | mldsa
device: raspberry-pi       # raspberry-pi | esp32
signing_mode: pi_client    # pi_client | esp32_direct | esp32_payload_only | esp32_gateway
load_profile: hospital-low # hospital-low | hospital-high
duration_minutes: 10
target_tps: 5              # ajustar conforme F2
warmup_transactions: 50
repetitions: 30
```

## Execução (previsto)

```bash
# Suíte completa — todos os cenários e cargas
./benchmarks/scripts/run_suite.sh --all

# Cenário isolado
./benchmarks/scripts/run_suite.sh --scenario C3 --load hospital-high
```

## Saída

- `benchmarks/results/<run_id>/metrics.csv`
- `benchmarks/results/<run_id>/metadata.json`

Resultados brutos não são versionados no git (ver `.gitignore`).
