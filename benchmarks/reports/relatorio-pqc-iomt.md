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
| **C1** | baseline | Raspberry Pi 4 | ECDSA-P256 | **coletado** (n=30, low/high) |
| **C2** | mldsa | Raspberry Pi 4 | ML-DSA-65 | **coletado** (n=30, low/high) |
| **C3** | baseline | ESP32-D | ECDSA (on-device, `esp32_direct`) | **coletado** (n=30, low/high) |
| **C4** | mldsa | ESP32-D | ML-DSA → `esp32_payload_only` | **coletado** (n=30, low/high) |

Nenhum cenário foi omitido. Em C4, a assinatura ML-DSA *on-device* no ESP32-D
resultou em falha reproduzível (`ESP_ERR_NOT_SUPPORTED`), coletada no modo de
*fallback* `esp32_payload_only`, conforme
[`cenarios-experimentais.md`](../../docs/cenarios-experimentais.md).

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
([`paridade-experimental.md`](../../docs/paridade-experimental.md)).

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

## 5. Resultados consolidados (coleta completa)

Coleta com **n=30 amostras** por (cenário × carga) + 10 transações de *warmup*
descartadas, totalizando **240 transações** confirmadas *on-chain*. C1/C2 no
Raspberry Pi 4 físico (arm64); C3/C4 via ponte MQTT → Fabric com *firmware*
regravado por cenário/carga. Latências em ms.

| Cenário | Disp. | Rede | Carga | p50 | p95 | TPS | CPU% | Sucesso |
|---------|-------|------|-------|-----|-----|-----|------|---------|
| C1 | Pi | baseline | low | 590.0 | 639.5 | 0.231 | 7.12 | 30/30 |
| C1 | Pi | baseline | high | 593.0 | 702.6 | 0.251 | 8.29 | 30/30 |
| C2 | Pi | mldsa | low | 597.5 | 690.8 | 0.220 | 8.01 | 30/30 |
| C2 | Pi | mldsa | high | 581.0 | 665.2 | 0.253 | 8.00 | 30/30 |
| C3 | ESP32 | baseline | low | 45.0 | 51.6 | 21.98 | — | 30/30 |
| C3 | ESP32 | baseline | high | 44.0 | 51.6 | 22.46 | — | 30/30 |
| C4 | ESP32 | mldsa | low | 43.0 | 50.8 | 22.74 | — | 30/30 |
| C4 | ESP32 | mldsa | high | 42.0 | 49.0 | 23.18 | — | 30/30 |

> ⚠️ A latência de C3/C4 mede o **relay** MQTT→Fabric no PC, **não** o custo de
> assinatura no microcontrolador (obtido por telemetria do dispositivo, §6).

### Dispersão da latência (média ± IC 95%, t de Student, n=30)

| Cenário | Carga | Média (ms) | DP (ms) | CV% | IC 95% (ms) |
|---------|-------|-----------|---------|-----|-------------|
| C1 | low  | 532,97 | 108,84 | 20,4 | [492,3; 573,6] |
| C1 | high | 584,67 | 94,50  | 16,2 | [549,4; 620,0] |
| C2 | low  | 607,00 | 34,86  | 5,7  | [594,0; 620,0] |
| C2 | high | 509,77 | 132,57 | 26,0 | [460,3; 559,3] |
| C3 | low  | 45,50  | 5,00   | 11,0 | [43,6; 47,4] |
| C3 | high | 44,53  | 3,25   | 7,3  | [43,3; 45,8] |
| C4 | low  | 43,97  | 4,30   | 9,8  | [42,4; 45,6] |
| C4 | high | 43,13  | 3,05   | 7,1  | [42,0; 44,3] |

> No Pi, a diferença C1↔C2 troca de sinal entre `low` e `high` — incompatível com
> um efeito sistemático de ML-DSA, reforçando H1/H2 não suportadas. Gerado por
> `analyze.py` (seção "Dispersão de latência" em `matriz-resultados.md`).

## 6. Análise por par

### C1 ↔ C2 — Raspberry Pi (ECDSA vs ML-DSA)

- **Latência:** variação de p95 entre $-5{,}3\%$ (high) e $+8{,}0\%$ (low); p50
  entre $-2\%$ e $+1{,}3\%$ — dentro do ruído de LAN (latência dominada por RTT +
  *endorsement*, não pela verificação da assinatura).
- **CPU:** equivalente (~7–8%) entre C1 e C2.
- **RAM:** ~466 MB (C1) → ~510–512 MB (C2), **+9,5–9,9%**, atribuível ao
  *footprint* da liboqs e às estruturas ML-DSA nos *peers*.
- **TPS:** mesma ordem (~0,22–0,25), limitado pelo cliente serial.
- **Assinatura (H3):** ML-DSA-65 ≈ **3309 B** (chave pública ≈ 1952 B) vs.
  ECDSA-P256 ≈ **64–72 B** (chave ≈ 33 B). Envelope *on-chain* em C2 confirmou a
  ordem (`signatureBytes` ≈ 4,4 KB em base64). Fator ≈ **46–52×**.

### C3 ↔ C4 — ESP32-D (ECDSA vs ML-DSA)

- **C3 (`esp32_direct`, ECDSA-P256 on-device):** assinatura local de ~**143–147 ms**
  por transação; *heap* livre estável ~213 KB (mín. ~209 KB), sem *resets*.
  Validada *on-chain* (`signAlg=ECDSA-P256`, `sign_ok=true`).
- **C4 (ML-DSA on-device — inviável → `esp32_payload_only`):** assinatura ML-DSA-65
  *on-device* retornou falha reproduzível (`ESP_ERR_NOT_SUPPORTED`,
  `sign_ok=false`, incremento de `sign_fail_total`). Coleta concluída em
  `esp32_payload_only` (assinatura PQC produzida pelo *relay*), 30/30 *on-chain*.
- **Leitura:** o ESP32-D executa ECDSA na borda com folga, mas **não** comporta
  ML-DSA-65 *on-device* na configuração avaliada — falha quantificada e válida (H5).

## 7. Hipóteses (veredito)

| ID | Hipótese | Veredito | Evidência |
|----|----------|----------|-----------|
| H1 | ML-DSA aumenta latência p95 vs ECDSA no Pi | **não suportada** | p95 +8,0% (low) / −5,3% (high), dentro do ruído |
| H2 | ML-DSA reduz TPS sob `hospital-high` | **não suportada** | C1 0,251 vs C2 0,253; limitado pelo cliente |
| H3 | Assinatura ML-DSA > 2× ECDSA (bytes) | **suportada** | ~46–52× (3309 B vs 64–72 B) |
| H4 | ESP32 degrada mais que Pi na migração PQC | **suportada** | ESP32 não assina ML-DSA on-device; Pi sim |
| H5 | C4 direto no ESP32 falha mais que C3 | **suportada** | `NOT_SUPPORTED`/memória vs C3 30/30 |

## 8. Limitações (ameaças à validade)

- Cliente de carga serial (peer-CLI) subestima TPS; usar Gateway/concorrência para
  avaliar vazão sob saturação.
- Latência de C3/C4 mede o *relay*, não o relógio fim-a-fim da borda; o custo
  criptográfico do dispositivo vem da telemetria (não subtraível diretamente).
- C4 não é PQC *on-device* (modo `esp32_payload_only`); comparar C3↔C4 ciente
  dessa assimetria de modo de assinatura.
- n=30 por célula em LAN isolada; generalização WAN/produção exige replicação.

## 9. Próximos passos (refinamento)

1. Teste de estresse com Fabric Gateway concorrente para TPS sob saturação.
2. Avaliar microcontrolador de maior capacidade (PSRAM) para ML-DSA *on-device*.
3. Explorar modo `esp32_gateway` formal para *offload* de assinatura PQC.
