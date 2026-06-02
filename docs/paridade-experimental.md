# Paridade experimental

Comparações baseline vs PQC só são válidas se:

1. **Mesma topologia** Fabric (nº peers, orderer, canal)
2. **Mesmo chaincode** e lógica de negócio
3. **Mesma carga** (nº transações, tamanho payload FHIR, intervalo)
4. **Mesmo hardware** e versão de OS/firmware por cenário C1–C4
5. **Mesmo endpoint** de medição (onde o cronômetro inicia/para)

Alterar apenas: algoritmo de assinatura (ECDSA vs ML-DSA) e build BCCSP correspondente.

Documentar qualquer exceção em `docs/decisoes-stack.md` antes do benchmark.
