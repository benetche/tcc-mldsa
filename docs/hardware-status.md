# Status de hardware — laboratório

Atualizado na branch `feat/f1-pilar-1-infra` (P1.2 concluído).

| Dispositivo | Status | Cenários | Notas |
|-------------|--------|----------|-------|
| **Raspberry Pi 4 Model B** | Validado C1 | C1, C2 | Cliente Fabric baseline; deploy `deploy-to-pi.sh` |
| **ESP32-D** | Pendente | C3, C4 | Documentar em `edge/esp32/`; não bloqueia Pilar 1 |

## Raspberry Pi 4 — baseline de laboratório (P1.2)

| Item | Valor |
|------|--------|
| Host SSH | `${PI_USER}@<IP_PI>` |
| Deploy remoto | `~/tcc-iomt/` (`PI_REMOTE_SUBDIR`) |
| Fabric peer (PC) | `<IP_PC>:7051` (auto `LAB_FABRIC_HOST`) |
| Cliente C1 | `peer-cli`, latência smoke **~320–440 ms** (2026-05-28) |
| Binário edge | `submit-observation` linux/arm64 (cross-compile no PC) |
| peer no Pi | Hyperledger Fabric **2.5.12** (arm64, instalado no deploy) |

Credenciais SSH: `edge/raspberry-pi/lab.env` (gitignored). Contexto: [.cursor/context/laboratorio-pi.md](../.cursor/context/laboratorio-pi.md).

### Coleta de métricas (pré-benchmark)

```bash
# No Pi (após deploy)
cd ~/tcc-iomt/edge/raspberry-pi
./scripts/collect_metrics.sh 30 1 /tmp/c1-metrics.csv
```

## ESP32-D

Pendente de hardware. C3/C4 documentados em `edge/esp32/README.md`.

## Deploy remoto (sem git no Pi)

No **PC de desenvolvimento** (Fabric baseline rodando):

```bash
cp edge/raspberry-pi/lab.env.example edge/raspberry-pi/lab.env
./edge/raspberry-pi/scripts/deploy-to-pi.sh
```

## Registro

| Data | Evento |
|------|--------|
| 2026-05-26 | Pi 4 disponível; início F1 + Pilar 1 |
| 2026-05-28 | **P1.2 concluído:** smoke C1 E2E no Pi físico via `deploy-to-pi.sh` |
