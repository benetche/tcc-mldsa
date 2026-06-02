# ECDSA P-256 vs ML-DSA-65 (liboqs)

Iterações por algoritmo: 50 (amd64, laboratório)

| Algoritmo | Chave pública (B) | Chave privada (B) | Assinatura (B) | KeyGen (ms) | Sign (ms) | Verify (ms) |

|-----------|-------------------|-------------------|----------------|-------------|-----------|-------------|

| ECDSA P-256 | 65 | 32 | 71 | 0.000 | 0.020 | 0.040 |
| ML-DSA-65 | 1952 | 4032 | 3309 | 0.020 | 0.060 | 0.020 |

## Notas

- ML-DSA-65 ≡ Dilithium3 (NIST FIPS 204).
- Tempos médios em amd64; repetir no Pi (arm64) para C2/C4.
- Integração Fabric BCCSP: task 06 (`fabric/mldsa/`).
