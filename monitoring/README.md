# Monitoramento — Pilar 5 (opcional)

Stack: **Prometheus + Grafana** (hosts e Raspberry Pi) + **MQTT (Mosquitto) + Telegraf** (ESP32-D).

## Início rápido

```bash
cd monitoring
cp .env.example .env        # ajuste credenciais do Grafana

# Núcleo: Prometheus + Grafana + node-exporter + cAdvisor
docker compose up -d

# + ponte ESP32/MQTT (Mosquitto + Telegraf)
docker compose --profile mqtt up -d

# Validação
./scripts/health-monitoring.sh
```

- Grafana: http://127.0.0.1:3000 (admin/admin por padrão; dashboard **IoMT — Monitoramento do laboratório**)
  - Seções: **ESP32-D**, **PC laboratório**, **Raspberry Pi 4**, **Fabric (Docker / Telegraf)**
  - Legendas: `ESP32 · {device_id}`, `PC laboratório`, `Fabric · {container}`, etc.
  - Variável de filtro: `ESP32 (device_id)`
- Prometheus: http://127.0.0.1:9090

## Alvos de coleta

| Dispositivo | Mecanismo | Porta |
|-------------|-----------|-------|
| PC / VM lab | node-exporter (container) | 9100 |
| Containers Fabric / IoMT | Telegraf `inputs.docker` (Docker API) | 9273 |
| Raspberry Pi | node_exporter (systemd) | 9100 |
| ESP32-D | MQTT → Telegraf → Prometheus | 1883 / 9273 |

> **Fabric no Grafana:** o cAdvisor neste host (cgroup v2 + overlayfs) não expõe o label `name` dos containers; as métricas de CPU/RAM dos peers/orderer/chaincode vêm do **Telegraf** (`docker_container_*`). O serviço `telegraf` precisa do GID do grupo `docker` no host (`user: "0:986"` em `docker-compose.yml` — ajuste `986` se `getent group docker` for outro).

### Raspberry Pi

No Pi: `sudo edge/raspberry-pi/scripts/install-node-exporter.sh`
No PC: copie `prometheus/targets/pi.json.example` → `prometheus/targets/pi.json`
com o IP do Pi (o file_sd carrega automaticamente; só `*.json` é lido).

### ESP32-D (sem hardware)

Simule métricas para validar a ponte:

```bash
docker compose --profile mqtt up -d
python3 scripts/mqtt-esp32-simulator.py --count 10 --interval 2
# (ou, sem paho-mqtt:)  python3 scripts/mqtt-esp32-simulator.py --via-docker
```

Contrato do payload: [edge/esp32/docs/METRICAS-MQTT.md](../edge/esp32/docs/METRICAS-MQTT.md).

## Documentação

- [Arquitetura e portas](docs/arquitetura-observabilidade.md)
- Arquitetura: [docs/arquitetura-observabilidade.md](docs/arquitetura-observabilidade.md)

## Segurança (laboratório)

Binds em `127.0.0.1` para Grafana/Prometheus/cAdvisor/Telegraf. MQTT/node-exporter
expostos na rede do lab (isolada). Sem PHI nos painéis. Dados de séries temporais
(`monitoring/data/`, volumes Docker) **não** são versionados.
