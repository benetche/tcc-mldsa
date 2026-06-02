# Cenários experimentais — matriz completa (robustez)

Objetivo: **executar e analisar todos os cenários C1–C4** para comparar ECDSA vs ML-DSA em Raspberry Pi 4 e ESP32-D, com metodologia equivalente.

## Matriz obrigatória

| ID | Rede | Dispositivo | Assinatura alvo | Status mínimo para TCC |
|----|------|-------------|-----------------|------------------------|
| **C1** | Baseline (ECDSA) | Raspberry Pi 4 | Cliente Fabric no Pi | Concluído |
| **C2** | ML-DSA | Raspberry Pi 4 | Cliente Fabric no Pi | Concluído |
| **C3** | Baseline (ECDSA) | ESP32-D | `esp32_direct` (ECDSA on-device) | Concluído |
| **C4** | ML-DSA | ESP32-D | `esp32_payload_only` (ML-DSA direto N/A) | Concluído |

Nenhum cenário pode ser omitido sem **evidência reproduzível** (logs, heap, taxa de falha). Falha em C4 no ESP32 **não invalida** o TCC se quantificada; **omitir** o cenário sem tentativa invalida a robustez declarada.

## Modos de assinatura no ESP32 (C3/C4)

Ordem de tentativa (registrar em `metadata.json` → `signing_mode`):

1. **`esp32_direct`** — ESP32 assina (ECDSA ou ML-DSA) e participa do envio à rede (cliente mínimo ou co-assinatura registrada no chaincode).
2. **`esp32_payload_only`** — ESP32 assina apenas hash/payload; Pi ou serviço submete tx Fabric (ainda conta como cenário C3/C4 se o gargalo medido for o ESP32).
3. **`esp32_gateway`** — **somente após** falha reproduzível em (1) ou (2): ESP32 envia ao Pi; Pi assina e submete. Rotular como subcenário `C3-gw` / `C4-gw` na análise, **sem substituir** C3/C4 diretos.

## Cargas de trabalho (por cenário)

Cada cenário C1–C4 deve rodar:

| Carga | Objetivo |
|-------|----------|
| `hospital-low` | Validar funcionamento e paridade |
| `hospital-high` | Estresse (alta frequência IoMT) |

Configuração em `benchmarks/scenarios/` (ver README).

## Métricas por cenário

- Latência E2E (média, p50, p95)
- TPS / taxa de confirmação
- Bytes: assinatura, payload FHIR, tx total
- Recursos: CPU/RAM (Pi); heap livre mínimo, resets (ESP32)
- Taxa de sucesso / timeout / OOM

## Repetições (robustez estatística)

| Requisito | Valor |
|-----------|--------|
| Warmup | ≥ 5 min ou N tx descartadas |
| Repetições por (cenário × carga) | **≥ 30** runs |
| Ordem de execução | Alternar baseline/PQC quando possível para evitar viés térmico |
| `metadata.json` | commit, Fabric version, `scenario_id`, `signing_mode`, firmware |

## Hipóteses

| ID | Hipótese |
|----|----------|
| H1 | ML-DSA aumenta latência p95 vs ECDSA no Pi (C1 vs C2) |
| H2 | ML-DSA reduz TPS sob `hospital-high` (C1 vs C2) |
| H3 | Assinatura ML-DSA > 2× ECDSA em bytes |
| H4 | ESP32 degrada mais que Pi na migração PQC (C3 vs C4 vs C1 vs C2) |
| H5 | C4 direto no ESP32 apresenta mais falhas que C3 (OOM/timeout) |

## Critério de conclusão do Pilar 4

- [x] Dados brutos para **C1, C2, C3, C4** × `hospital-low` e `hospital-high` (≥30 amostras)
- [x] Relatório com tabelas **C1↔C2** e **C3↔C4** — [relatorio-pqc-iomt.md](../benchmarks/reports/relatorio-pqc-iomt.md)
- [x] `signing_mode` documentado por run ESP32 (C4: `esp32_payload_only`)
- [x] Reprodução via `run_suite.sh --all` e análise com `analyze.py`

## Referências

- Estado do projeto: [estado-do-projeto.md](estado-do-projeto.md)
- Paridade: [paridade-experimental.md](paridade-experimental.md)
- Scripts: [benchmarks/scripts/README.md](../benchmarks/scripts/README.md)
- Stack: [decisoes-stack.md](decisoes-stack.md)
