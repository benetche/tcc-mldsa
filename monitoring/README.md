# Monitoramento — Pilar 5 (opcional)

Stack **Prometheus + Grafana** para PC e Raspberry Pi, e **MQTT + Telegraf** para métricas do ESP32-D. Complementa benchmarks pontuais com séries temporais; não substitui `benchmarks/results/`.

Arquitetura: [docs/arquitetura-observabilidade.md](docs/arquitetura-observabilidade.md).

## Início rápido

```bash
cd monitoring
cp .env.example .env

docker compose up -d
docker compose --profile mqtt up -d   # Mosquitto + Telegraf (ESP32)

./scripts/health-monitoring.sh
```

| Serviço | URL local |
|---------|-----------|
| Grafana | http://127.0.0.1:3000 |
| Prometheus | http://127.0.0.1:9090 |

Dashboard: **IoMT — Monitoramento do laboratório** (ESP32, PC, Pi, containers Fabric).

## Alvos

| Origem | Coleta | Porta |
|--------|--------|-------|
| PC / VM | node-exporter (container) | 9100 |
| Docker (Fabric, CCAAS) | Telegraf `inputs.docker` | 9273 |
| Raspberry Pi | node_exporter (systemd) | 9100 |
| ESP32-D | MQTT → Telegraf | 1883 → 9273 |

**Pi:** `sudo edge/raspberry-pi/scripts/install-node-exporter.sh`  
**Prometheus:** copiar `prometheus/targets/pi.json.example` → `pi.json` com `<PI_HOST>`.

**Fabric no Grafana:** métricas de containers via Telegraf (`docker_container_*`). Ajustar GID do grupo `docker` em `docker-compose.yml` se necessário (`getent group docker`).

## ESP32 sem hardware físico

```bash
docker compose --profile mqtt up -d
python3 scripts/mqtt-esp32-simulator.py --count 10 --interval 2
```

Contrato MQTT: [edge/esp32/docs/METRICAS-MQTT.md](../edge/esp32/docs/METRICAS-MQTT.md).

## Segurança

- Binds `127.0.0.1` para UI e Prometheus no PC
- MQTT/node_exporter na VLAN de laboratório
- Sem PHI nos painéis
- `monitoring/data/` e volumes Docker não versionados
