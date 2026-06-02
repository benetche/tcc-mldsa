# ESP32-D — borda IoMT (C3 / C4)

Firmware **ESP-IDF** para cenários **C3** (ECDSA-P256, `esp32_direct`) e **C4** (tentativa ML-DSA-65).

## Hardware detectado (lab)

- Porta típica: `/dev/ttyUSB0` (adaptador CH340)
- Verificar: `./scripts/detect-esp32.sh`
- Permissão: usuário no grupo `dialout`

## Pré-requisitos

1. [ESP-IDF v5.x](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/get-started/)
2. Wi-Fi e broker MQTT do laboratório (stack `monitoring/` — Mosquitto)
3. Copiar `main/secrets.h.example` → `main/secrets.h` (gitignored)

## Configuração

```bash
cd edge/esp32
cp main/secrets.h.example main/secrets.h
# editar SSID, senha, URI mqtt://<host>:1883

idf.py set-target esp32
idf.py menuconfig   # IoMT ESP32: cenário C3 ou C4, device_id, intervalo
```

## Build e flash

```bash
# Primeira vez: clone + ./install.sh esp32 em ~/esp/esp-idf (ver docs Espressif)
source ./scripts/setup-idf-env.sh
export ESPPORT=/dev/ttyUSB0
idf.py build
./scripts/build-flash-monitor.sh   # build + flash + monitor
```

**Antes do flash:** edite `main/secrets.h` (senha Wi-Fi real) e rode `sudo usermod -aG dialout $USER` (logout/login).

## Cenários

| ID | Build | Assinatura | MQTT |
|----|-------|------------|------|
| **C3** | `IOMT_SCENARIO_C3` (default) | ECDSA-P256 em NVS | métricas + observação assinada |
| **C4** | `IOMT_SCENARIO_C4` | ML-DSA stub (`ESP_ERR_NOT_SUPPORTED`) | publica falha para telemetria |

Tópicos (Pilar 5): `iomt/esp32/{device_id}/metrics` e `.../observation`.

Payload de métricas: [docs/METRICAS-MQTT.md](docs/METRICAS-MQTT.md).

## Validação

```bash
./scripts/validate-esp32.sh
DO_BUILD=1 ./scripts/validate-esp32.sh   # com ESP-IDF
```

Stub estrutural C3/C4 (YAML): `./scripts/validate-c3-c4-stub.sh`.

## Próximos passos (task 04)

- [ ] Smoke E2E C3 → Fabric (via Pi/gateway ou cliente mínimo)
- [ ] C4: integrar liboqs ou documentar `esp32_payload_only`
- [ ] Benchmarks `run_suite.sh` com hardware real

Ver [cenarios-experimentais.md](../../.cursor/context/cenarios-experimentais.md).
