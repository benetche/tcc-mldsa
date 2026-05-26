# Decisões de stack — TCC ML-DSA + Fabric + IoMT

> **Fase F1** — branch `feat/f1-pilar-1-infra` (2026-05-26)

## Status

| Área | Status | Notas |
|------|--------|-------|
| Blockchain | definido | Hyperledger Fabric 2.5 LTS |
| PQC | definido | ML-DSA-65 (Dilithium3) via liboqs + BCCSP (Pilar 2) |
| Dados | definido | MIMIC-IV + FHIR R4 (Pilar 3) |
| Raspberry Pi | em uso | C1/C2 — único hardware disponível |
| ESP32 | pendente | C3/C4 — ver [hardware-status.md](./hardware-status.md) |

---

## 1. Plataforma blockchain

**Escolha:** [Hyperledger Fabric](https://hyperledger-fabric.readthedocs.io/) **2.5.x** (LTS), rede permissionada de laboratório.

| Perfil | Diretório | Assinatura (MSP/BCCSP) |
|--------|-----------|-------------------------|
| Baseline | `fabric/baseline/` | ECDSA (padrão Fabric) |
| PQC | `fabric/mldsa/` | ML-DSA via BCCSP customizado (Pilar 2) |

**Provisionamento:** scripts em `fabric/baseline/scripts/` sobre o **test-network** do repositório [fabric-samples](https://github.com/hyperledger/fabric-samples) (clone local, não versionado).

**Canal:** `iomtchannel`  
**Chaincode:** `iomt` (Go) — registro de observações IoMT / hash FHIR

**Justificativa:** Fabric é permissionado, adotado em cenários corporativos/saúde, e expõe **BCCSP** para substituição de ECDSA por ML-DSA — alinhado ao objetivo do TCC. Alternativa de nó customizado (Go puro) foi rejeitada por não refletir o ecossistema Fabric nem o desafio de integração BCCSP.

---

## 2. Papel dos dispositivos

| Dispositivo | Status | Papel na rede Fabric |
|-------------|--------|----------------------|
| **Raspberry Pi 4** | Disponível | **Cliente** (Fabric Gateway / SDK); coleta métricas; pode hospedar peers em dev |
| **ESP32-D** | Pendente | **Cliente IoMT** ultraleve (C3/C4); assinatura no dispositivo como meta |

**Fluxo (Pi — C1):** Wi-Fi/LAN → Gateway → endorse chaincode `iomt` → commit no canal `iomtchannel`.

**Peers/orderer:** executam em Docker no host de desenvolvimento ou no Pi (64-bit); não no ESP32.

---

## 3. Criptografia pós-quântica (Pilar 2)

| Função | Algoritmo | Parâmetro |
|--------|-----------|-----------|
| Assinatura | ML-DSA | **ML-DSA-65** (Dilithium3, NIST FIPS 204) |

**Biblioteca:** [liboqs](https://github.com/open-quantum-safe/liboqs) integrada ao **BCCSP** do Fabric.

**Baseline:** ECDSA P-256 (Fabric default).

---

## 4. Dados de saúde (Pilar 3)

| Item | Escolha |
|------|---------|
| Dataset | MIMIC-IV (credenciais PhysioNet; dados fora do git) |
| Intercâmbio | HL7 **FHIR R4** (`Patient`, `Observation`, `Device`) |
| Dev sem MIMIC | Fixtures em `health-data/fixtures/` |

**Escopo MIMIC (inicial):** sinais vitais em `chartevents` / `vitalsign` conforme disponibilidade após credenciamento.

---

## 5. Stack Raspberry Pi

| Item | Escolha |
|------|---------|
| SO | Raspberry Pi OS **64-bit** (Bookworm) |
| Cliente | **fabric-gateway-go** v1.x |
| Deploy rede (dev) | Docker Compose via test-network |
| Métricas | scripts em `edge/raspberry-pi/scripts/` |

---

## 6. Stack ESP32 (quando disponível)

| Item | Escolha |
|------|---------|
| Framework | ESP-IDF 5.2+ |
| Crypto baseline | mbedTLS (ECDSA) |
| PQC | liboqs enxuto ou delegação — avaliar em C4 |

---

## 7. Riscos e mitigações

| Risco | Mitigação |
|-------|-----------|
| BCCSP/Fabric complexo | Versão Fabric fixa; escopo mínimo sign/verify |
| ESP32 indisponível no Pilar 1 | Focar C1; C3/C4 com Pi + doc de pendência |
| ML-DSA no ESP32 | Fallback `esp32_payload_only`; falha quantificada |
| MIMIC atrasado | Fixtures FHIR sintéticas |

---

## 8. Hipóteses preliminares (benchmarks)

Ver [cenarios-experimentais.md](../.cursor/context/cenarios-experimentais.md) — H1 a H5.

---

## Histórico

| Data | Alteração |
|------|-----------|
| 2026-05-26 | Documento inicial F1 — Fabric 2.5, Pi ativo, ESP32 pendente |
