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

O comando `idf.py` **só existe depois** de carregar o ESP-IDF. Se o terminal do Cursor mostrar
`exit code: 127` ou `idf.py: comando não encontrado`, use um dos caminhos abaixo.

```bash
cd edge/esp32
export ESPPORT=/dev/ttyUSB0

# Opção A (recomendada): wrapper — não precisa de source manual
./idf.sh build
./idf.sh -p /dev/ttyUSB0 flash monitor

# Opção B: script all-in-one
./scripts/build-flash-monitor.sh

# Opção C: source no shell atual, depois idf.py
source ./scripts/setup-idf-env.sh
idf.py build
```

Primeira vez: clone + `./install.sh esp32` em `~/esp/esp-idf` (ver docs Espressif).

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

### E2E C3 → Fabric (MQTT relay)

Pré-requisitos: Fabric baseline UP, Mosquitto no lab, ESP32 flashado (C3).

```bash
MQTT_HOST=<IP_PC> ./scripts/smoke-e2e-c3.sh
```

Detalhes: [docs/PONTE-MQTT-FABRIC.md](docs/PONTE-MQTT-FABRIC.md).

### C4 (stub ML-DSA + relay)

Firmware C4 publica sem assinatura PQC; relay classifica `esp32_payload_only`:

```bash
MQTT_HOST=<IP_PC> ./scripts/smoke-c4-relay.sh   # rede mldsa
```

### Benchmarks

```bash
MQTT_HOST=<IP_PC> ./scripts/run-esp32-benchmark.sh C3 hospital-low
# ou: export IOMT_ESP32_BRIDGE=mqtt && ./benchmarks/scripts/run_suite.sh --scenario C3 --samples 30
```

Payload MQTT usa `recorded_at` em **RFC3339** (UTC) após SNTP no Wi-Fi.

Ver [cenarios-experimentais.md](../../.cursor/context/cenarios-experimentais.md).
