# Status de hardware — laboratório

Atualizado na branch `feat/f1-pilar-1-infra`.

| Dispositivo | Status | Cenários | Notas |
|-------------|--------|----------|-------|
| **Raspberry Pi 4 Model B** | Disponível | C1, C2 | Cliente Fabric + ingestão; pode hospedar rede em dev |
| **ESP32-D** | Pendente | C3, C4 | Documentar em `edge/esp32/`; não bloqueia Pilar 1 inicial |

## Escopo atual (Pilar 1)

- Implementar e validar **C1** (Pi + rede Fabric baseline ECDSA).
- Preparar estrutura para **C2** após Pilar 2 (ML-DSA).
- ESP32: apenas README e checklist; benchmarks C3/C4 quando hardware chegar.

## Registro

| Data | Evento |
|------|--------|
| 2026-05-26 | Pi 4 disponível; início F1 + Pilar 1 sem ESP32 |
