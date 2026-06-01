#!/usr/bin/env python3
"""
Simulador de métricas do ESP32-D para validar a ponte MQTT → Telegraf → Prometheus
sem hardware. Publica JSON em iomt/esp32/{device_id}/metrics.

Uso:
  python3 mqtt-esp32-simulator.py --device esp32-ward-01 --count 10 --interval 2
  python3 mqtt-esp32-simulator.py --via-docker   # usa mosquitto_pub no container

Sem paho-mqtt instalado, cai no fallback `docker exec iomt-mosquitto mosquitto_pub`.
"""

from __future__ import annotations

import argparse
import json
import random
import subprocess
import sys
import time


def sample(device_id: str, sign_alg: str) -> dict:
    return {
        "device_id": device_id,
        "ts": int(time.time()),
        "heap_free": random.randint(38000, 50000),
        "heap_min": random.randint(34000, 38000),
        "cpu_percent": round(random.uniform(5, 35), 1),
        "wifi_rssi_dbm": random.randint(-75, -50),
        "net_tx_bytes": random.randint(1024, 8192),
        "net_rx_bytes": random.randint(2048, 16384),
        "sign_alg": sign_alg,
        "sign_duration_ms": round(
            random.uniform(35, 60) if sign_alg == "ECDSA" else random.uniform(180, 900), 1
        ),
    }


def publish_docker(topic: str, payload: str, container: str, host: str, port: int) -> None:
    subprocess.run(
        ["docker", "exec", container, "mosquitto_pub", "-h", host, "-p", str(port),
         "-t", topic, "-m", payload],
        check=True,
    )


def main() -> None:
    ap = argparse.ArgumentParser(description="Simulador MQTT de métricas ESP32")
    ap.add_argument("--host", default="localhost")
    ap.add_argument("--port", type=int, default=1883)
    ap.add_argument("--device", default="esp32-ward-01")
    ap.add_argument("--sign-alg", default="ECDSA", choices=["ECDSA", "ML-DSA-65"])
    ap.add_argument("--count", type=int, default=5)
    ap.add_argument("--interval", type=float, default=2.0)
    ap.add_argument("--via-docker", action="store_true",
                    help="publica via 'docker exec iomt-mosquitto mosquitto_pub'")
    ap.add_argument("--container", default="iomt-mosquitto")
    args = ap.parse_args()

    topic = f"iomt/esp32/{args.device}/metrics"

    client = None
    if not args.via_docker:
        try:
            import paho.mqtt.client as mqtt  # type: ignore
            client = mqtt.Client()
            client.connect(args.host, args.port, 60)
            client.loop_start()
        except ImportError:
            print("[sim] paho-mqtt ausente → fallback docker exec mosquitto_pub", file=sys.stderr)
        except Exception as ex:  # noqa: BLE001
            print(f"[sim] conexão MQTT falhou ({ex}) → fallback docker", file=sys.stderr)

    for i in range(args.count):
        payload = json.dumps(sample(args.device, args.sign_alg))
        if client is not None:
            client.publish(topic, payload, qos=0)
        else:
            publish_docker(topic, payload, args.container,
                           "localhost", args.port)
        print(f"[sim] {i+1}/{args.count} → {topic}: {payload}")
        if i < args.count - 1:
            time.sleep(args.interval)

    if client is not None:
        client.loop_stop()
        client.disconnect()
    print("[sim] concluído")


if __name__ == "__main__":
    main()
