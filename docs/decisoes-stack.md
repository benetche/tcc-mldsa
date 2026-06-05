# Decisões de stack — TCC ML-DSA + Fabric + IoMT

Registro das escolhas técnicas que sustentam implementação, benchmarks e monografia. 

## Resumo

| Área | Escolha | Situação |
|------|---------|----------|
| Blockchain | Hyperledger Fabric **2.5.x** LTS | Implementado (`baseline` + `mldsa`) |
| PQC | **ML-DSA-65** (Dilithium3) via liboqs + BCCSP | Implementado |
| Dados | MIMIC-IV + FHIR R4 | Implementado (fixtures + ingestão) |
| Borda Pi | C1/C2, Fabric Gateway / peer-cli | Validado |
| Borda ESP32 | C3/C4, MQTT + relay | Validado (C4 com fallback) |
| Monitoramento | Prometheus + Grafana + MQTT | Opcional, implementado |

---

## 1. Plataforma blockchain

**Escolha:** [Hyperledger Fabric](https://hyperledger-fabric.readthedocs.io/) **2.5.x**, rede permissionada de laboratório.

| Perfil | Diretório | Assinatura (MSP/BCCSP) |
|--------|-----------|-------------------------|
| Baseline | `fabric/baseline/` | ECDSA (padrão Fabric) |
| PQC | `fabric/mldsa/` | ML-DSA via BCCSP customizado |

**Provisionamento:** scripts em `fabric/baseline/scripts/` sobre o **test-network** do [fabric-samples](https://github.com/hyperledger/fabric-samples) (clone local, não versionado).

**Canal:** `iomtchannel`  
**Chaincode:** `iomt` (Go) — observações IoMT, hash/payload FHIR

**Justificativa:** rede permissionada com **BCCSP** extensível para ML-DSA, alinhada ao ecossistema adotado em cenários corporativos e de saúde.

---

## 2. Papel dos dispositivos

| Dispositivo | Papel |
|-------------|-------|
| **Raspberry Pi 4** | Cliente Fabric (C1/C2); métricas; opcional node_exporter |
| **ESP32-D** | Cliente IoMT ultraleve (C3/C4); assinatura on-device quando viável |
| **PC de desenvolvimento** | Peers, orderer, CCAAS, broker MQTT, build e orquestração |

**Fluxo Pi:** LAN → endorse chaincode `iomt` → commit em `iomtchannel`.  
**Fluxo ESP32:** Wi-Fi → MQTT → relay/ponte → Fabric (C3 direto; C4 com `esp32_payload_only`).

Peers e orderer **não** rodam no ESP32.

---

## 3. Criptografia pós-quântica (Pilar 2)

| Função | Algoritmo | Parâmetro |
|--------|-----------|-----------|
| Assinatura PQC | ML-DSA | **ML-DSA-65** (Dilithium3, NIST FIPS 204) |
| Baseline | ECDSA | P-256 (Fabric default) |

**Biblioteca:** [liboqs](https://github.com/open-quantum-safe/liboqs) no BCCSP do Fabric.

### Comparativo de tamanhos e tempos (amd64, laboratório)

Fonte: `crypto/docs/ecdsa-vs-mldsa.md` (`crypto/scripts/benchmark-crypto.sh`).

| Algoritmo | Chave pública (B) | Assinatura (B) | Sign (ms) | Verify (ms) |
|-----------|-------------------|----------------|-----------|-------------|
| ECDSA P-256 | 65 | 71 | ~0,02 | ~0,04 |
| ML-DSA-65 | 1952 | 3309 | ~0,06 | ~0,02 |

### Escopo implementado

| Camada | Baseline | ML-DSA (`fabric/mldsa`) |
|--------|----------|-------------------------|
| BCCSP peer/orderer | ECDSA (SW) | ML-DSA-65 (`build-fabric-mldsa.sh`, `tcc/fabric-peer-mldsa`) |
| Assinatura borda (Pi) | ECDSA-P256 on-chain | ML-DSA-65 on-chain |
| MSP ML-DSA lab | — | BCCSP lab → `mspSignAlg` / `mspSignature` (`test-msp-mldsa-endorse.sh`) |
| Envelope X.509 (User1/peer) | ECDSA | ECDSA (limitação Fabric 2.5 sem cert PQ) |

Validação: `fabric/mldsa/scripts/close-pilar-2.sh`.

---

## 4. Dados de saúde (Pilar 3)

| Item | Escolha |
|------|---------|
| Dataset | MIMIC-IV (PhysioNet; dados fora do git) |
| Intercâmbio | HL7 **FHIR R4** (`Patient`, `Observation`, `Device`) |
| Sem MIMIC | Fixtures `health-data/fixtures/` (`dataSource: SYNTHETIC`) |

**Implementado:** mappings, schemas, `scripts/ingestion/` (`ingest_hospital.py`, perfis `hospital-low`/`hospital-high`), chaincode `RegisterFhirObservation`. Acesso: [mimic-acesso.md](./mimic-acesso.md).

---

## 5. Stack Raspberry Pi

| Item | Escolha |
|------|---------|
| SO | Raspberry Pi OS **64-bit** (Bookworm) |
| Cliente | peer-cli / fabric-gateway-go |
| Métricas | `edge/raspberry-pi/scripts/` |

---

## 6. Stack ESP32

| Item | Escolha |
|------|---------|
| Framework | ESP-IDF 5.x |
| Crypto baseline | mbedTLS (ECDSA-P256) |
| PQC on-device | ML-DSA **não** viável → C4 via `esp32_payload_only` |

---

## 7. Riscos e mitigações

| Risco | Mitigação |
|-------|-----------|
| Complexidade BCCSP/Fabric | Versão fixa 2.5; escopo mínimo sign/verify |
| ML-DSA no ESP32 | Fallback documentado; falha quantificada em C4 |
| MIMIC indisponível | Fixtures FHIR sintéticas |
| Portas em conflito | Não rodar `baseline` e `mldsa` simultaneamente |

---

## 8. Hipóteses de benchmark

Ver [cenarios-experimentais.md](cenarios-experimentais.md) — H1 a H5. Resultados: [relatorio-pqc-iomt.md](../benchmarks/reports/relatorio-pqc-iomt.md).

---

## 9. Monitoramento (Pilar 5 — opcional)

| Item | Escolha |
|------|---------|
| Visualização | Grafana |
| Séries | Prometheus |
| Pi / PC | node_exporter |
| Containers | cAdvisor + Telegraf (`inputs.docker`) |
| ESP32 | MQTT → Telegraf → Prometheus |

Implementação: `monitoring/`, [arquitetura-observabilidade.md](../monitoring/docs/arquitetura-observabilidade.md). Sem exposição à internet pública.
