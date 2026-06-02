#!/usr/bin/env python3
"""
Ponte MQTT → Fabric para C3/C4 (esp32_payload_only / relay).

O ESP32 assina no dispositivo e publica JSON em iomt/esp32/{device_id}/observation.
Este script consome e invoca RegisterObservation no chaincode.

Uso:
  # Uma observação (smoke E2E)
  ./mqtt_fabric_bridge.py --once

  # Loop (laboratório)
  ./mqtt_fabric_bridge.py --count 10 --interval 2

  # Via Mosquitto no Docker
  ./mqtt_fabric_bridge.py --once --via-docker
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "scripts" / "ingestion"))

from esp32_mqtt_bridge import (  # noqa: E402
    MqttObservationQueue,
    run_mqtt_listener,
    wait_and_submit_one,
)
from fabric_client import FabricConfig  # noqa: E402


def main() -> None:
    ap = argparse.ArgumentParser(description="Ponte MQTT ESP32 → Fabric")
    ap.add_argument("--host", default=os.environ.get("MQTT_HOST", "localhost"))
    ap.add_argument("--port", type=int, default=int(os.environ.get("MQTT_PORT", "1883")))
    ap.add_argument("--device", default=os.environ.get("IOMT_DEVICE_ID", "esp32-ward-01"))
    ap.add_argument("--once", action="store_true", help="processa uma observação e sai")
    ap.add_argument("--count", type=int, default=0, help="0 = infinito até --once")
    ap.add_argument("--timeout", type=float, default=30.0)
    ap.add_argument("--via-docker", action="store_true")
    ap.add_argument("--container", default="iomt-mosquitto")
    args = ap.parse_args()

    topic = f"iomt/esp32/{args.device}/observation"
    os.environ.setdefault("REPO_ROOT", str(ROOT))
    cfg = FabricConfig.from_env()
    q = MqttObservationQueue()
    run_mqtt_listener(args.host, args.port, topic, q, via_docker=args.via_docker, container=args.container)

    print(f"[mqtt-bridge] aguardando {topic} em {args.host}:{args.port}", file=sys.stderr)

    def do_one() -> dict:
        return wait_and_submit_one(cfg, q, timeout_s=args.timeout)

    if args.once:
        result = do_one()
        print(json.dumps(result, indent=2))
        return

    n = args.count or 10**9
    for i in range(n):
        try:
            result = do_one()
            print(
                f"[{i}] ok id={result['observation_id']} "
                f"mode={result['signing_mode_effective']} "
                f"lat={result['latency_ms']}ms signAlg={result.get('signAlg')}"
            )
        except Exception as ex:  # noqa: BLE001
            print(f"[{i}] erro: {ex}", file=sys.stderr)
        time.sleep(0.5)


if __name__ == "__main__":
    main()
