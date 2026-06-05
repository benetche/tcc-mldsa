# TCC — Blockchain permissionada pós-quântica para IoMT

Implementação e análise de **Hyperledger Fabric** com **ML-DSA (Dilithium)** em substituição ao **ECDSA**, aplicada ao monitoramento **IoMT** em cenário hospitalar simulado (**MIMIC-IV** + **HL7 FHIR**).

## Objetivo

Quantificar o impacto da migração pós-quântica em:

- Tamanho de assinaturas e payloads
- Latência de confirmação (E2E)
- Vazão (TPS)
- Consumo de CPU e RAM (Raspberry Pi 4, ESP32-D)

## Estado atual

A matriz experimental **C1–C4** (Pi e ESP32 × ECDSA e ML-DSA) foi implementada e **coletada** com séries robustas (≥30 amostras por cenário e carga). Resumo completo: **[docs/estado-do-projeto.md](docs/estado-do-projeto.md)**.

| Pilar | Conteúdo | Situação |
|-------|----------|----------|
| 1 | Fabric baseline + mldsa, borda Pi/ESP32 | Concluído |
| 2 | liboqs + BCCSP ML-DSA | Concluído |
| 3 | FHIR, ingestão, chaincode | Concluído |
| 4 | Benchmarks e relatório | Coleta concluída |
| 5 | Prometheus/Grafana/MQTT | Opcional, disponível |

## Estrutura do repositório

```
fabric/          # Redes baseline (ECDSA) e mldsa (ML-DSA)
crypto/          # liboqs, BCCSP, benchmarks de primitivas
health-data/     # Mappings MIMIC→FHIR, fixtures, schemas
scripts/ingestion/   # Cargas hospitalares e cliente Fabric
edge/            # raspberry-pi (C1/C2), esp32 (C3/C4)
benchmarks/      # Cenários YAML, scripts, relatórios
monitoring/      # Stack opcional de observabilidade
docs/            # Documentação de referência do TCC
```

## Início rápido

### Rede Fabric (baseline)

```bash
cd fabric/baseline
./scripts/bootstrap-samples.sh    # uma vez
./scripts/network-up.sh
./scripts/deploy-chaincode.sh
./scripts/test-chaincode.sh
```

### Rede ML-DSA

```bash
./crypto/scripts/build-liboqs.sh
./crypto/scripts/build-fabric-mldsa.sh
cd fabric/mldsa && ./scripts/build-peer-image.sh && ./scripts/network-up.sh
```

### Borda Raspberry Pi (C1 ou C2)

```bash
cp edge/raspberry-pi/lab.env.example edge/raspberry-pi/lab.env   # editar IPs/credenciais
cd edge/raspberry-pi && ./scripts/deploy-to-pi.sh
```

### ESP32 (C3 ou C4)

```bash
cp edge/esp32/main/secrets.h.example edge/esp32/main/secrets.h
cd edge/esp32 && ./idf.sh build && ./idf.sh -p /dev/ttyUSB0 flash
export MQTT_HOST=<IP_DO_BROKER>
./scripts/smoke-e2e-c3.sh
```

### Benchmark completo

```bash
./benchmarks/scripts/run_suite.sh --all
python3 benchmarks/scripts/analyze.py --glob '*'
```

## Documentação

| Documento | Descrição |
|-----------|-----------|
| [estado-do-projeto.md](docs/estado-do-projeto.md) | Status por pilar e cenário C1–C4 |
| [decisoes-stack.md](docs/decisoes-stack.md) | Stack técnica e escopo PQC |
| [arquitetura.md](docs/arquitetura.md) | Topologia Fabric e fluxo de dados |
| [cenarios-experimentais.md](docs/cenarios-experimentais.md) | Matriz, hipóteses H1–H5, métricas |
| [paridade-experimental.md](docs/paridade-experimental.md) | Regras baseline ↔ ML-DSA |
| [laboratorio-local.md](docs/laboratorio-local.md) | Credenciais locais (não versionadas) |
| [hardware-status.md](docs/hardware-status.md) | Dispositivos e comandos de validação |

READMEs por módulo: `fabric/baseline/`, `fabric/mldsa/`, `crypto/`, `edge/raspberry-pi/`, `edge/esp32/`, `health-data/`, `benchmarks/scripts/`, `monitoring/`.

## Cenários experimentais

| ID | Rede | Dispositivo |
|----|------|-------------|
| C1 | ECDSA | Raspberry Pi 4 |
| C2 | ML-DSA | Raspberry Pi 4 |
| C3 | ECDSA | ESP32-D |
| C4 | ML-DSA | ESP32-D (fallback `esp32_payload_only`) |

Configs: [benchmarks/scenarios/](benchmarks/scenarios/). Relatório: [benchmarks/reports/relatorio-pqc-iomt.md](benchmarks/reports/relatorio-pqc-iomt.md).

## Segurança e dados sensíveis

Não versionar: `lab.env`, `secrets.h`, `sdkconfig`, dados MIMIC brutos, `benchmarks/results/`, targets Prometheus com IPs reais, chaves MSP. Ver `.gitignore`.

## Licença e uso acadêmico

Repositório de Trabalho de Conclusão de Curso — rede de **laboratório isolada**, sem chaves de produção nem dados clínicos reais.
