# Monitoramento — Pilar 5 (opcional)

Stack: **Prometheus + Grafana** (hosts e Raspberry Pi) + **MQTT + Telegraf** (ESP32-D).

## Status

Planejado — ver task `.cursor/tasks/12-monitoramento-observabilidade.md`.

## Início rápido (quando implementado)

```bash
cd monitoring
docker compose up -d
# Grafana: http://127.0.0.1:3000  (credenciais em .env.example)
# Prometheus: http://127.0.0.1:9090
```

## Documentação

- [Arquitetura e portas](docs/arquitetura-observabilidade.md)
- Roadmap: [.cursor/roadmap/pilar-5-monitoramento.md](../.cursor/roadmap/pilar-5-monitoramento.md)

## Métricas por dispositivo

| Dispositivo | Mecanismo |
|-------------|-----------|
| PC / VM lab | node_exporter → Prometheus |
| Raspberry Pi | node_exporter (arm64) |
| Docker / Fabric | cAdvisor |
| ESP32-D | MQTT → Telegraf → Prometheus |

Não versionar dados de séries temporais (`monitoring/data/` está no `.gitignore` quando existir).
