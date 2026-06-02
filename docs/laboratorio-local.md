# Laboratório local

Configuração **fora do repositório** para repetir os cenários C1–C4 em rede isolada (LAN). Nenhum IP, senha ou credencial real deve ser commitado.

## Arquivos locais obrigatórios

| Arquivo | Uso | Template |
|---------|-----|----------|
| `edge/raspberry-pi/lab.env` | SSH, IP do Pi, rede Fabric (`baseline`/`mldsa`) | `lab.env.example` |
| `edge/raspberry-pi/config.env` | MSP e endpoints no Pi (gerado no deploy) | `config.example.env` |
| `edge/esp32/main/secrets.h` | Wi-Fi, URI MQTT | `secrets.h.example` |
| `edge/esp32/sdkconfig` | Opções ESP-IDF (gerado pelo build) | `sdkconfig.defaults` |
| `monitoring/.env` | Senha Grafana | `.env.example` |
| `monitoring/prometheus/targets/pi.json` | IP do Pi para Prometheus | `pi.json.example` |

## Raspberry Pi (C1 / C2)

1. `cp edge/raspberry-pi/lab.env.example edge/raspberry-pi/lab.env`
2. Preencher `PI_HOST`, `PI_USER` e autenticação (senha em `PI_SSH_PASSWORD` ou chave SSH).
3. `LAB_FABRIC_HOST`: IP do PC com Fabric na LAN (vazio = auto no deploy).
4. `FABRIC_NETWORK`: `baseline` (C1) ou `mldsa` (C2).
5. Deploy: `cd edge/raspberry-pi && ./scripts/deploy-to-pi.sh`

Guia operacional: [FLUXO-CENARIOS-PI.md](../edge/raspberry-pi/docs/FLUXO-CENARIOS-PI.md).

## ESP32 (C3 / C4)

1. `cp edge/esp32/main/secrets.h.example edge/esp32/main/secrets.h`
2. Ajustar SSID, senha Wi-Fi e `mqtt://<host>:1883`.
3. Build/flash: [edge/esp32/README.md](../edge/esp32/README.md).
4. Nos scripts do PC: `export MQTT_HOST=<IP_DO_BROKER>` antes de smoke/benchmark.

Broker Mosquitto: perfil `mqtt` em `monitoring/docker-compose.yml`.

## PC de desenvolvimento

- Docker para Fabric e, opcionalmente, monitoramento.
- Portas típicas: **7050** (orderer), **7051** / **9051** (peers), **1883** (MQTT).
- Não executar `fabric/baseline` e `fabric/mldsa` ao mesmo tempo.

## Segurança

- Preferir **chave SSH** no Pi e remover senha de `lab.env` quando possível.
- Rotacionar credenciais se expostas em log ou chat.
- Dados MIMIC apenas em disco local (`MIMIC_DATA_PATH`, gitignored).

## Validação rápida

```bash
# Pi
cd edge/raspberry-pi && ./scripts/validate-pi-scenarios.sh

# ESP32 (com broker e MQTT_HOST)
cd edge/esp32 && MQTT_HOST=<IP> ./scripts/smoke-e2e-c3.sh
```

Status dos dispositivos: [hardware-status.md](hardware-status.md).
