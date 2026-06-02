# Hardware de laboratório

Dispositivos usados na matriz **C1–C4**. Credenciais e IPs ficam em arquivos locais (gitignored) — ver [laboratorio-local.md](laboratorio-local.md).

## Visão geral

| Dispositivo | Cenários | Capacidades validadas |
|-------------|----------|------------------------|
| **Raspberry Pi 4 Model B** | C1, C2 | Deploy remoto, smoke E2E, ingestão FHIR, benchmarks no Pi |
| **ESP32-D** | C3, C4 | ECDSA on-device (C3); C4 com fallback `esp32_payload_only`; ponte MQTT→Fabric |

## Raspberry Pi 4

| Item | Detalhe |
|------|---------|
| Acesso | SSH via `PI_USER` / `PI_HOST` em `edge/raspberry-pi/lab.env` |
| Diretório remoto | `~/tcc-iomt/` (`PI_REMOTE_SUBDIR`) |
| Fabric | Peer no PC (`LAB_FABRIC_HOST:7051`, auto no deploy) |
| C1 | `smoke-c1.sh`, assinatura ECDSA-P256 na borda |
| C2 | `smoke-c2.sh`, ML-DSA-65 (liboqs arm64 no Pi) |
| Binário edge | `submit-observation` (linux/arm64) |
| peer no Pi | Hyperledger Fabric **2.5.12** (arm64, instalado no deploy) |
| Latência smoke C1 | Ordem de centenas de ms (LAN + dois endossos) |

### Coleta de métricas

| Método | Comando / artefato |
|--------|-------------------|
| CSV local | `./scripts/collect_metrics.sh 30 1 /tmp/metrics.csv` |
| Prometheus | `install-node-exporter.sh` + `monitoring/prometheus/targets/pi.json` |
| Durante benchmark | `run-pi-benchmark.sh` → `resources.csv` por execução |

### Validação (a partir do PC)

```bash
cd edge/raspberry-pi
./scripts/validate-pi-scenarios.sh --deploy
```

## ESP32-D

| Item | Detalhe |
|------|---------|
| Porta USB | `/dev/ttyUSB0` (adaptador CH340 típico) |
| Rede | Wi-Fi e MQTT em `main/secrets.h` ou menuconfig |
| C3 | ECDSA-P256 (`esp32_direct`) |
| C4 | ML-DSA on-device não suportado → relay `esp32_payload_only` |
| Smoke E2E | `edge/esp32/scripts/smoke-e2e-c3.sh` (requer `MQTT_HOST`) |
| Benchmark | `run-esp32-benchmark.sh` / `run-esp32-benchmark-all.sh` |

Documentação: [edge/esp32/README.md](../edge/esp32/README.md), [PONTE-MQTT-FABRIC.md](../edge/esp32/docs/PONTE-MQTT-FABRIC.md).

## Deploy remoto do Pi (sem git no dispositivo)

No PC com Fabric em execução:

```bash
cp edge/raspberry-pi/lab.env.example edge/raspberry-pi/lab.env
# editar PI_HOST, PI_USER, FABRIC_NETWORK (baseline ou mldsa)
./edge/raspberry-pi/scripts/deploy-to-pi.sh
```

Estado geral do projeto: [estado-do-projeto.md](estado-do-projeto.md).
