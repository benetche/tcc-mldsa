# Pilar 2 — Escopo de MSP e assinatura ML-DSA

## Objetivo original

Substituir ECDSA por **ML-DSA-65** no **BCCSP** do Hyperledger Fabric e validar impacto em IoMT.

## O que foi alcançado (critério de fechamento P2)

1. **BCCSP ML-DSA no peer/orderer** — binários e imagem Docker com factory `MLDSA` (liboqs).
2. **Transação Fabric endorse + commit** — `test-chaincode.sh`, C2 no Pi.
3. **Assinatura MSP ML-DSA verificável** — `msp-mldsa-sign` usa o mesmo provedor `crypto/bccsp` que o BCCSP Fabric; digest `MSP-endorse-v1|obsId|payloadHash|recordedAt`; campos `mspSignAlg` / `mspSignature` no ledger.
4. **Teste no container peer** — `test-peer-bccsp-mldsa.sh` (`bccsp-smoke`).

## Limitação explícita (Fabric 2.5)

O **MSP padrão** exige identidades **X.509** com chaves ECDSA/RSA no certificado. Certificados ML-DSA ainda não são suportados pelo parser `crypto/x509` usado no MSP. Por isso:

- O **envelope** da transação (proposta do cliente, endosso interno do peer com identidade Fabric CA) permanece **ECDSA**.
- A **prova criptográfica ML-DSA ao estilo MSP** é registrada on-chain e reproduzível via `fabric/mldsa/scripts/test-msp-mldsa-endorse.sh`.

Evolução futura: Fabric CA + certificados PQ (OpenSSL 3 + OQS provider) ou MSP customizado.

## Comandos

```bash
./fabric/mldsa/scripts/close-pilar-2.sh
./fabric/mldsa/scripts/test-msp-mldsa-endorse.sh
./fabric/mldsa/scripts/test-peer-bccsp-mldsa.sh
```
