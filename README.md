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
docs/            # arquitetura, cenários, laboratório, decisões de stack
```

A pasta `.cursor/` (agentes Cursor, roadmap interno) fica **fora do git** — use localmente se trabalhar com o IDE.

## Documentação principal

- [Decisões de stack](docs/decisoes-stack.md)
- [Cenários experimentais C1–C4](docs/cenarios-experimentais.md)
- [Paridade experimental](docs/paridade-experimental.md)
- [Laboratório local](docs/laboratorio-local.md) — `lab.env` / `secrets.h` (não versionados)
- [Status de hardware](docs/hardware-status.md)
- Configs de carga: [benchmarks/scenarios/](benchmarks/scenarios/)

## Cenários experimentais (robustez)

Matriz **2×2 obrigatória**: C1 (Pi+ECDSA), C2 (Pi+ML-DSA), C3 (ESP32+ECDSA), C4 (ESP32+ML-DSA).  
Detalhes: [docs/cenarios-experimentais.md](docs/cenarios-experimentais.md).

## Status

Branch ativa: **`feat/f1-pilar-1-infra`** — F0/F1/F2 documentados; Fabric baseline + cliente Pi (C1) em implementação.  
ESP32: ver [hardware-status.md](docs/hardware-status.md).
