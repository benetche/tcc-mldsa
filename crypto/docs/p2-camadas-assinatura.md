# Pilar 2 — Camadas de assinatura

## Três camadas (monografia)

| Camada | C1 (baseline) | C2 (mldsa) | MSP Fabric (peers) |
|--------|---------------|------------|---------------------|
| **Borda (Pi/ESP32)** | ECDSA-P256 (`edgesign`) | ML-DSA-65 (`sign-payload` + liboqs) | — |
| **Cliente Fabric (User1)** | ECDSA (Fabric CA) | ECDSA (Fabric CA) | — |
| **Peer / orderer (BCCSP)** | ECDSA nativo | ML-DSA-65 no binário peer | TLS/MSP ainda ECDSA da CA |

## O que está validado no P2

- **C1:** rede `baseline`, assinatura **ECDSA-P256 na borda** gravada no chaincode (`signAlg`, `deviceSignature`).
- **C2:** rede `mldsa`, peer com **BCCSP MLDSA**, assinatura **ML-DSA-65 na borda** on-chain.
- **C3/C4:** fixtures YAML + stub `edge/esp32/scripts/validate-c3-c4-stub.sh` (`hardware_pending`).

## Próximo passo (fora do escopo mínimo P2)

MSP X.509 com chaves ML-DSA nos certificados Fabric (identidade de proposta/endosso 100% PQC).

## Scripts

```bash
./benchmarks/scripts/validate-p2-scenarios.sh
./edge/raspberry-pi/scripts/validate-local-submit.sh baseline
./edge/raspberry-pi/scripts/validate-local-submit.sh mldsa
```

Após alterar o chaincode: `fabric/*/scripts/deploy-chaincode.sh`.
