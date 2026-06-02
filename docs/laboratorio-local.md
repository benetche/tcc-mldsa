# Laboratório local (Pi + PC + ESP32)

> **Credenciais e IPs reais não ficam no repositório.** Configure `edge/raspberry-pi/lab.env` (copie de `lab.env.example`) e `edge/esp32/main/secrets.h` (copie de `secrets.h.example`).

## Raspberry Pi 4 (C1/C2)

1. `cp edge/raspberry-pi/lab.env.example edge/raspberry-pi/lab.env`
2. Preencha `PI_HOST`, `PI_USER` e, se necessário, `PI_SSH_PASSWORD` ou chave SSH.
3. Deixe `LAB_FABRIC_HOST` vazio para auto-detecção no deploy, ou informe o IP do PC onde o Fabric escuta na LAN.
4. Deploy: `cd edge/raspberry-pi && ./scripts/deploy-to-pi.sh`

Guia detalhado: [edge/raspberry-pi/docs/FLUXO-CENARIOS-PI.md](../edge/raspberry-pi/docs/FLUXO-CENARIOS-PI.md).

## ESP32-D (C3/C4)

1. `cp edge/esp32/main/secrets.h.example edge/esp32/main/secrets.h` — SSID, senha Wi-Fi e URI MQTT.
2. Broker Mosquitto no PC ou Pi; exporte `MQTT_HOST` nos scripts de smoke/benchmark.
3. Flash: ver [edge/esp32/README.md](../edge/esp32/README.md).

## Segurança

- Nunca commitar `lab.env`, `config.env`, `secrets.h`, `sdkconfig` ou arquivos `*.pem` / `*_sk` de MSP.
- Preferir chave SSH no Pi e remover senha de `lab.env` quando possível.
- Rotacionar credenciais se expostas em log ou chat.

## Status do hardware

Resumo público (sem credenciais): [hardware-status.md](hardware-status.md).
