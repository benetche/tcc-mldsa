# TCC — Blockchain permissionada pós-quântica para IoMT

Implementação e análise de **Hyperledger Fabric** com **ML-DSA (Dilithium)** substituindo **ECDSA**, voltada ao monitoramento de dispositivos **IoMT** em cenário hospitalar simulado (**MIMIC-IV** + **HL7 FHIR**).

## Objetivo

Medir o impacto da migração pós-quântica em:

- Tamanho de assinaturas
- Latência de rede
- Vazão (TPS)
- Consumo de CPU/RAM (Raspberry Pi, ESP32)

## Quatro pilares

| Pilar | Descrição |
|-------|-----------|
| **1 — Infraestrutura** | Fabric, rede permissionada, dispositivos de borda |
| **2 — Criptografia** | liboqs + BCCSP, ML-DSA |
| **3 — Dados de saúde** | MIMIC-IV, ingestão FHIR |
| **4 — Benchmarking** | Testes de estresse e análise comparativa |

## Navegação no repositório

```
fabric/          # baseline (ECDSA) e mldsa
crypto/          # liboqs, extensão BCCSP
health-data/     # mappings e fixtures FHIR
edge/            # raspberry-pi, esp32
benchmarks/      # cenários, scripts, relatórios
docs/            # monografia, decisões de stack
.cursor/         # agentes, roadmap, tasks, rules
```

## Cursor — como começar

1. Leia o [roadmap](.cursor/roadmap/ROADMAP.md)
2. Execute a [task 00](.cursor/tasks/00-fundacao-repositorio.md)
3. Use os agentes por pilar:
   - `@pilar-1-infraestrutura-agent`
   - `@pilar-2-criptografia-agent`
   - `@pilar-3-dados-saude-agent`
   - `@pilar-4-benchmark-agent`
   - `@edge-iomt-agent` (Pi/ESP32)
   - `@tcc-academic-agent` (monografia)

## Cenários experimentais (robustez)

Matriz **2×2 obrigatória**: C1 (Pi+ECDSA), C2 (Pi+ML-DSA), C3 (ESP32+ECDSA), C4 (ESP32+ML-DSA).  
Detalhes: [.cursor/context/cenarios-experimentais.md](.cursor/context/cenarios-experimentais.md) · Configs: [benchmarks/scenarios/](benchmarks/scenarios/)

## Status

Projeto em fase de **organização inicial** — ver [registro de progresso](.cursor/roadmap/ROADMAP.md#registro-de-progresso).
