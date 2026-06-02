# Documentação do TCC

Índice da documentação **versionada** do repositório. Estado consolidado do trabalho: **[estado-do-projeto.md](./estado-do-projeto.md)**.

## Visão e metodologia

| Documento | Conteúdo |
|-----------|----------|
| [estado-do-projeto.md](./estado-do-projeto.md) | Status por pilar, matriz C1–C4, limitações |
| [decisoes-stack.md](./decisoes-stack.md) | Fabric 2.5, ML-DSA-65, MIMIC/FHIR, hardware |
| [arquitetura.md](./arquitetura.md) | Topologia, fluxo Pi/ESP32 → Fabric |
| [cenarios-experimentais.md](./cenarios-experimentais.md) | Matriz obrigatória, hipóteses, métricas |
| [paridade-experimental.md](./paridade-experimental.md) | Paridade ECDSA vs ML-DSA nos benchmarks |

## Laboratório e operação

| Documento | Conteúdo |
|-----------|----------|
| [laboratorio-local.md](./laboratorio-local.md) | `lab.env`, `secrets.h`, deploy |
| [hardware-status.md](./hardware-status.md) | Pi, ESP32, validação e métricas |
| [mimic-acesso.md](./mimic-acesso.md) | Credenciais PhysioNet (fora do git) |

## Referências e relatórios

| Documento | Conteúdo |
|-----------|----------|
| [referencias.md](./referencias.md) | Rascunho bibliográfico ABNT |
| [../benchmarks/reports/relatorio-pqc-iomt.md](../benchmarks/reports/relatorio-pqc-iomt.md) | Relatório Pilar 4 (metodologia + resultados) |

## Documentação por módulo

| Pasta | README |
|-------|--------|
| `fabric/baseline/` | Rede ECDSA, chaincode, C1 |
| `fabric/mldsa/` | Rede ML-DSA, imagem peer, C2 |
| `crypto/` | liboqs, BCCSP, benchmarks de primitivas |
| `edge/raspberry-pi/` | Cliente Pi; [FLUXO-CENARIOS-PI.md](../edge/raspberry-pi/docs/FLUXO-CENARIOS-PI.md) |
| `edge/esp32/` | Firmware C3/C4; [PONTE-MQTT-FABRIC.md](../edge/esp32/docs/PONTE-MQTT-FABRIC.md) |
| `health-data/` | FHIR e fixtures |
| `scripts/ingestion/` | Ingestão hospitalar |
| `benchmarks/scripts/` | Suíte e análise |
| `monitoring/` | Prometheus, Grafana, MQTT |
