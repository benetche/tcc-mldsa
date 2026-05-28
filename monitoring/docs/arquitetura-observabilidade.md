# Arquitetura de observabilidade — TCC IoMT

Pilar **opcional** (P5). Stack principal: **Prometheus + Grafana**.

## Visão geral

```text
┌─────────────┐     scrape      ┌──────────────┐     query      ┌─────────┐
│ node_export │ ──────────────► │  Prometheus  │ ◄───────────── │ Grafana │
│ (host, Pi)  │                 │   :9090      │                │  :3000  │
└─────────────┘                 └──────▲───────┘                └─────────┘
┌─────────────┐     scrape            │
│  cAdvisor   │ ──────────────────────┤
│  (Docker)   │                       │
└─────────────┘                       │
┌─────────────┐   MQTT    ┌──────────┴───┐  prometheus_client
│   ESP32-D   │ ────────► │ Mosquitto    │ ─────► Telegraf :9273
└─────────────┘           └──────────────┘
```

## Compatibilidade por hardware

### Raspberry Pi 4 (64-bit)

| Componente | Suporte | Notas |
|------------|---------|-------|
| node_exporter | Nativo arm64 | Métricas de SO: CPU, memória, disco, rede |
| Prometheus | Nativo arm64 | Preferir retenção curta (7d) e `--storage.tsdb.retention.time` |
| Grafana | Nativo arm64 | UI em `:3000`; refresh mínimo 5s nos painéis |
| Telegraf + Mosquitto | Nativo arm64 | Útil se o broker MQTT ficar no Pi |

**Recomendação:** em laboratório com PC potente, rodar Prometheus/Grafana no PC e apenas **node_exporter** no Pi. Se o PC estiver ausente, stack completa no Pi com recursos limitados.

### ESP32-D

O ESP32 **não** executa Prometheus, Grafana nem node_exporter.

| Abordagem | Viabilidade |
|-----------|-------------|
| Publicar métricas via **MQTT** (JSON) | Recomendada — poucos KB RAM, biblioteca `esp_mqtt` no ESP-IDF |
| HTTP push para **Pushgateway** | Possível, mas mais custoso em TLS/parsing |
| Agente tipo node_exporter | Impossível no MCU |

**Contrato MQTT sugerido**

- Tópico: `iomt/esp32/{device_id}/metrics`
- Payload (JSON, QoS 0 ou 1):

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
  "sign_alg": "ECDSA",
  "sign_duration_ms": 48
}
```

Telegraf (`inputs.mqtt_consumer`) parseia campos e expõe para Prometheus via `outputs.prometheus_client`.

## Métricas Fabric (Docker)

Containers do test-network (`peer0.org1`, `orderer`, `peer0org1_iomt_ccaas`, etc.) são monitorados com **cAdvisor** no host:

- `container_cpu_usage_seconds_total`
- `container_memory_usage_bytes`
- `container_network_*`

Isso complementa (não substitui) latência/TPS medidos em `benchmarks/scripts/`.

## Portas padrão (lab)

| Serviço | Porta | Bind sugerido |
|---------|-------|----------------|
| Grafana | 3000 | 127.0.0.1 |
| Prometheus | 9090 | 127.0.0.1 |
| node_exporter | 9100 | IP do host/Pi |
| cAdvisor | 8080 | 127.0.0.1 |
| Mosquitto | 1883 | rede lab |
| Telegraf (Prometheus plugin) | 9273 | 127.0.0.1 |

## Integração com benchmarks (P4)

Durante `run_suite.sh` ou `ingest_hospital.py`:

1. Anotar no Grafana o intervalo do teste (annotation API) com cenário C1–C4 e perfil `hospital-low`/`high`.
2. Correlacionar picos de CPU no Pi com latência p95 do CSV de benchmark.
3. Para ESP32 em C3/C4, correlacionar `sign_duration_ms` MQTT com taxa de timeout.

## Segurança

- Ambiente **isolado**; sem exposição WAN.
- Dashboards sem PHI — apenas métricas de sistema e contadores IoMT.
- MQTT sem TLS aceitável só em VLAN de bancada; documentar na monografia.

## Referências

- [Prometheus — node_exporter](https://github.com/prometheus/node_exporter)
- [Grafana — provisioning](https://grafana.com/docs/grafana/latest/administration/provisioning/)
- [Telegraf — MQTT Consumer](https://docs.influxdata.com/telegraf/latest/plugins/inputs/mqtt_consumer/)
- [ESP-IDF — MQTT](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-reference/protocols/mqtt.html)
