# Ponte MQTT → Fabric (C3 / C4)

O ESP32 assina no dispositivo (C3: ECDSA-P256) e publica JSON no tópico
`iomt/esp32/{device_id}/observation`. O PC ou Pi executa o relay para o chaincode
`RegisterObservation`.

## Modos de assinatura (paridade experimental)

| Modo | Quem assina | Quando |
|------|-------------|--------|
| `esp32_direct` | ESP32 | C3 com `deviceSignature` + `signAlg` no payload MQTT |
| `esp32_payload_only` | Relay (sem assinatura de borda) | C4 stub sem ML-DSA on-device; hash + metadados vêm do ESP |
| `esp32_gateway` | Pi/HTTP | Último recurso — rotular em `metadata.json` se usado |

A ponte Python (`scripts/ingestion/esp32_mqtt_bridge.py`) define o modo efetivo a
partir do payload e grava em `metadata.json` (`signing_mode_effective`, `relay: mqtt`).

## Comandos

```bash
# Smoke E2E C3 (ESP32 publicando + Fabric baseline)
MQTT_HOST=<IP_DO_BROKER> ./edge/esp32/scripts/smoke-e2e-c3.sh

# Uma observação manual
python3 edge/esp32/scripts/mqtt_fabric_bridge.py --once

# Benchmark formal (≥30 amostras)
MQTT_HOST=<IP_DO_BROKER> ./edge/esp32/scripts/run-esp32-benchmark.sh C3 hospital-low
```

Variáveis: `MQTT_HOST`, `MQTT_PORT`, `IOMT_DEVICE_ID`, `FABRIC_PEER_ENDPOINT`,
`IOMT_ESP32_BRIDGE=mqtt` (usado por `run_suite.sh` para C3/C4).
