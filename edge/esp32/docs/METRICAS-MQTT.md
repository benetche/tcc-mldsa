# Métricas ESP32-D via MQTT (Pilar 5)

O ESP32 **não** executa Prometheus/Grafana. Publica métricas em JSON no broker MQTT; **Telegraf** no host/Pi converte para Prometheus.

## Tópico

```text
iomt/esp32/{device_id}/metrics
```

## Payload de exemplo

```json
{
  "device_id": "esp32-ward-01",
  "ts": 1716921600,
  "heap_free": 45280,
  "heap_min": 38120,
  "cpu_percent": 12.5,
  "wifi_rssi_dbm": -62,
  "net_tx_bytes": 4096,
  "net_rx_bytes": 8192,
  "sign_alg": "ECDSA-P256",
  "sign_ok": true,
  "sign_duration_ms": 152.0,
  "sign_duration_crypto_ms": 45.0,
  "sign_fail_total": 0
}
```

## Campos

| Campo | Descrição |
|-------|-----------|
| `heap_free` / `heap_min` | Memória heap (bytes) |
| `cpu_percent` | Carga estimada do loop principal / idle hook |
| `wifi_rssi_dbm` | Qualidade do link Wi-Fi |
| `net_tx_bytes` / `net_rx_bytes` | Contadores de rede desde boot |
| `sign_duration_ms` | Tempo total `iomt_sign_payload()` (NVS + hash + sign + base64) |
| `sign_duration_crypto_ms` | Tempo só de `mbedtls_pk_sign` (C3) |
| `sign_ok` | `true` se assinatura on-device OK |
| `sign_fail_total` | Contador acumulado de falhas (C4 / H5) |

## Referências

- [monitoring/docs/arquitetura-observabilidade.md](../../../monitoring/docs/arquitetura-observabilidade.md)
- [ESP-IDF MQTT](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-reference/protocols/mqtt.html)
