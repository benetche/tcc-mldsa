# Estado do projeto

Visão consolidada do TCC **Blockchain permissionada pós-quântica para IoMT** (Hyperledger Fabric + ML-DSA + MIMIC-IV/FHIR).

## Resumo executivo

| Área | Estado | Evidência principal |
|------|--------|---------------------|
| **Pilar 1 — Infraestrutura** | Concluído | `fabric/baseline`, `fabric/mldsa`, deploy Pi, firmware ESP32 |
| **Pilar 2 — Criptografia** | Concluído | liboqs, BCCSP ML-DSA, imagem `tcc/fabric-peer-mldsa`, smoke C2 |
| **Pilar 3 — Dados de saúde** | Concluído | FHIR, fixtures, `scripts/ingestion`, chaincode `RegisterFhirObservation` |
| **Pilar 4 — Benchmarking** | Coleta concluída | C1–C4 × low/high (n≥30); ver [relatório](../benchmarks/reports/relatorio-pqc-iomt.md) |
| **Pilar 5 — Monitoramento** | Opcional, implementado | `monitoring/` (Prometheus, Grafana, MQTT/Telegraf) |
| **Monografia** | Em elaboração | `monografia/` (gitignored no repositório público) |

## Matriz experimental C1–C4

| ID | Rede | Dispositivo | Assinatura na borda | E2E / smoke | Benchmark (n≥30 × 2 cargas) |
|----|------|-------------|---------------------|-------------|------------------------------|
| **C1** | baseline (ECDSA) | Raspberry Pi 4 | ECDSA-P256 | Validado | Coletado |
| **C2** | mldsa (ML-DSA) | Raspberry Pi 4 | ML-DSA-65 | Validado | Coletado |
| **C3** | baseline | ESP32-D | ECDSA (`esp32_direct`) | Validado (MQTT → Fabric) | Coletado |
| **C4** | mldsa | ESP32-D | ML-DSA on-device **não suportado** → `esp32_payload_only` | Validado com fallback documentado | Coletado |

Detalhes metodológicos: [cenarios-experimentais.md](cenarios-experimentais.md).

### Resultado destacado — C4 no ESP32

A tentativa de assinatura **ML-DSA-65 no dispositivo** retorna falha reproduzível (`ESP_ERR_NOT_SUPPORTED`). O cenário C4 foi executado e medido no modo **`esp32_payload_only`** (relay MQTT + submissão Fabric no host), conforme previsto na matriz quando o modo direto não é viável.

## Componentes por pasta

| Pasta | Função | Situação |
|-------|--------|----------|
| `fabric/baseline/` | Rede ECDSA, canal `iomtchannel`, chaincode `iomt` | Operacional |
| `fabric/mldsa/` | Peers com BCCSP ML-DSA (`tcc/fabric-peer-mldsa`) | Operacional |
| `crypto/` | liboqs, binding Go, build Fabric PQC | Operacional |
| `health-data/` | Mappings MIMIC→FHIR, fixtures, schemas | Operacional |
| `scripts/ingestion/` | Cargas `hospital-low` / `hospital-high` | Operacional |
| `edge/raspberry-pi/` | Cliente C1/C2, deploy remoto, benchmarks no Pi | Operacional |
| `edge/esp32/` | Firmware C3/C4, ponte MQTT, benchmarks | Operacional |
| `benchmarks/` | Suíte, análise, relatório versionado | Coleta feita; resultados brutos locais |
| `monitoring/` | Dashboards e métricas de borda | Opcional |
| `docs/` | Arquitetura, stack, laboratório | Documentação de referência |

## Hardware de laboratório

| Dispositivo | Papel | Configuração |
|-------------|-------|--------------|
| **PC de desenvolvimento** | Docker Fabric, Mosquitto, Prometheus/Grafana, build ESP32 | Rede LAN isolada |
| **Raspberry Pi 4** | Cliente Fabric C1/C2, node_exporter | `edge/raspberry-pi/lab.env` (gitignored) |
| **ESP32-D** | Sensor/ator C3/C4, publicação MQTT | `edge/esp32/main/secrets.h` (gitignored) |

Sem credenciais ou IPs reais no repositório — ver [laboratorio-local.md](laboratorio-local.md) e [hardware-status.md](hardware-status.md).

## Limitações conhecidas (documentadas)

- **Envelope MSP Fabric 2.5:** identidades X.509 dos peers/usuários permanecem em **ECDSA**; ML-DSA atua no BCCSP de laboratório e na assinatura de borda on-chain.
- **ESP32 + ML-DSA direto:** inviável no hardware atual; C4 usa fallback `esp32_payload_only`.
- **MIMIC-IV:** dataset fora do git; fixtures sintéticas para CI e desenvolvimento sem credencial PhysioNet.
- **Baseline e mldsa:** não subir as duas redes simultaneamente (mesmas portas).

## Próximos passos sugeridos

1. Consolidar capítulos da monografia a partir de [relatorio-pqc-iomt.md](../benchmarks/reports/relatorio-pqc-iomt.md) e artefatos gerados por `analyze.py`.
2. Publicar repositório após revisão de histórico Git (IPs antigos em commits anteriores do `.cursor/`, se aplicável).
3. Manter `.cursor/` apenas local para agentes IDE (gitignored).

## Documentação relacionada

- [decisoes-stack.md](decisoes-stack.md) — escolhas técnicas
- [arquitetura.md](arquitetura.md) — topologia e fluxos
- [paridade-experimental.md](paridade-experimental.md) — regras de comparação ECDSA vs ML-DSA
