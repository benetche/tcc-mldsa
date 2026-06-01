# Relatório de benchmarks — PQC vs ECDSA em IoMT/Fabric (Pilar 4)

> Documento **versionado** (metodologia + interpretação). As tabelas de
> resultados agregados (`matriz-resultados.md`, `summary.json`) e os gráficos
> (`figures/`) são **gerados** por `analyze.py` a partir de `benchmarks/results/`
> (dados brutos, gitignored) e **não** são versionados.

## 1. Objetivo

Quantificar o impacto da migração **ECDSA → ML-DSA (Dilithium)** em uma rede
Hyperledger Fabric permissionada com ingestão FHIR (IoMT), sobre a matriz
obrigatória **C1–C4** (Raspberry Pi e ESP32-D × baseline e PQC).

## 2. Matriz experimental

| ID | Rede | Dispositivo | Assinatura na borda | Status atual |
|----|------|-------------|---------------------|--------------|
| **C1** | baseline | Raspberry Pi 4 | ECDSA-P256 | **mensurável** (rede + Pi) |
| **C2** | mldsa | Raspberry Pi 4 | ML-DSA-65 | pendente rede `mldsa` no ar |
| **C3** | baseline | ESP32-D | ECDSA (on-device) | `hardware_pending` |
| **C4** | mldsa | ESP32-D | ML-DSA (on-device/fallback) | `hardware_pending` |

Nenhum cenário é omitido: C3/C4 são registrados como `hardware_pending` com
metadados, conforme [`cenarios-experimentais.md`](../../.cursor/context/cenarios-experimentais.md).

## 3. Infraestrutura de benchmark

| Componente | Arquivo |
|------------|---------|
| Orquestrador | `benchmarks/scripts/run_suite.sh` |
| Runner (1 cenário × 1 carga) | `benchmarks/scripts/bench_lib.py` |
| Análise / tabelas / gráficos | `benchmarks/scripts/analyze.py` |
| Cenários | `benchmarks/scenarios/c{1..4}-*.yaml` |
| Cargas | `benchmarks/scenarios/hospital-{low,high}.yaml` |

O runner reaproveita a **ingestão FHIR do Pilar 3** (`scripts/ingestion`,
pacote `iomt_fhir`) — mesma lógica de payload e mesmo chaincode
`RegisterFhirObservation` — garantindo **paridade experimental**
([`experimental-parity.mdc`](../../.cursor/rules/experimental-parity.mdc)).

### Métricas coletadas por execução

- Latência E2E por transação → média, **p50**, **p95** (`metrics.csv`)
- TPS (transações confirmadas / tempo medido)
- Bytes de payload FHIR canônico
- CPU% e RAM via `/proc/stat` e `/proc/meminfo` (`resources.csv`)
- Taxa de sucesso vs erro de endosso
- `metadata.json`: `scenario_id`, `signing_mode`, commit, versão do Fabric, host

## 4. Reprodução

```bash
# Pré-requisito: rede Fabric no ar (fabric/baseline/scripts/network-up.sh)
# venv com PyYAML (reaproveita scripts/ingestion/.venv)

# Suíte completa (C1–C4 × low/high)
./benchmarks/scripts/run_suite.sh --all

# Cenário único com série robusta (≥30 amostras + warmup)
./benchmarks/scripts/run_suite.sh --scenario C1 --samples 30 --warmup 10

# Validação rápida sem rede
./benchmarks/scripts/run_suite.sh --all --dry-run

# Agregar e gerar tabelas/gráficos
python3 benchmarks/scripts/analyze.py --glob '*'
```

**Robustez estatística (TCC):** ≥ 30 amostras por (cenário × carga), com warmup
descartado. Repetir `run_suite.sh` acumula execuções em `results/`; `analyze.py`
agrega todas as que casarem com `--glob`.

## 5. Resultados preliminares (validação do pipeline)

> ⚠️ **Preliminar.** Medições feitas no **host de desenvolvimento** atuando como
> cliente (peer-CLI), com **amostra reduzida** (12 tx) apenas para validar a
> ferramenta. **Não** substituem a série ≥30 executada no **Raspberry Pi físico**.

| Cenário | Carga | tx | p50 (ms) | p95 (ms) | TPS | Payload (B) | CPU% | Sucesso |
|---------|-------|----|----------|----------|-----|-------------|------|---------|
| C1 | hospital-low | 12 | ~49 | ~61 | 0.32 | 591 | ~9 | 100% |
| C1 | hospital-high | 12 | ~45 | ~51 | 0.38 | 591 | ~9 | 100% |

**Observações metodológicas:**

- O **TPS** observado é limitado pelo cliente **serial peer-CLI** (um invoke +
  confirmação por query, com espera de ~2 s) — **não** é o teto da rede. Para TPS
  real de estresse, usar cliente concorrente (Fabric Gateway, múltiplos workers)
  na fase de coleta final.
- A **latência E2E** (~45–61 ms p95) reflete invoke + endosso de 2 orgs no host.
  No Pi, espera-se latência maior (medir em C1 real no hardware).
- O **payload FHIR canônico** (~591 B) é idêntico entre cenários por construção
  (paridade) — a diferença esperada entre C1 e C2 está na **assinatura**, não no payload.

## 6. Análise por par (preencher após coleta completa)

### C1 ↔ C2 — Raspberry Pi (ECDSA vs ML-DSA)

- Comparar p95, TPS e CPU/RAM sob `hospital-low` e `hospital-high`.
- Medir bytes de **assinatura** na borda (ECDSA-P256 ≈ 64–72 B; ML-DSA-65 ≈ 3309 B)
  via o submit edge (`edge/raspberry-pi`), correlacionando com H3.

### C3 ↔ C4 — ESP32-D (ECDSA vs ML-DSA)

- Requer hardware. Registrar `signing_mode` efetivo: `esp32_direct` →
  `esp32_payload_only` → `esp32_gateway` (último com evidência).
- Falha/OOM/timeout em C4 é **dado válido** (H5), não descarte.

## 7. Hipóteses

| ID | Hipótese | Status |
|----|----------|--------|
| H1 | ML-DSA aumenta latência p95 vs ECDSA no Pi | aguarda C2 |
| H2 | ML-DSA reduz TPS sob `hospital-high` | aguarda C2 + cliente concorrente |
| H3 | Assinatura ML-DSA > 2× ECDSA (bytes) | esperado por construção; medir na borda |
| H4 | ESP32 degrada mais que Pi na migração PQC | aguarda C3/C4 (hardware) |
| H5 | C4 direto no ESP32 falha mais que C3 | aguarda C3/C4 (hardware) |

## 8. Limitações

- Cliente de carga serial (peer-CLI) subestima TPS; usar Gateway/concorrência na coleta final.
- C2 exige a rede `mldsa` (peer BCCSP ML-DSA) ativa — ver `fabric/mldsa/`.
- C3/C4 dependem de hardware ESP32-D (`docs/hardware-status.md`).
- Medições preliminares no host ≠ Raspberry Pi (apenas validação de pipeline).

## 9. Próximos passos

1. Subir rede `mldsa` e coletar **C2** (≥30 × low/high) no Pi.
2. Coletar **C1** definitivo no Pi físico (`deploy-to-pi.sh` + `run_suite.sh`).
3. Integrar bytes de assinatura da borda ao relatório (H3).
4. Quando houver ESP32: **C3/C4** com `signing_mode` documentado.
5. Exportar figuras (`analyze.py` com `matplotlib`) para a monografia (task 11).
