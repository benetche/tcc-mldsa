"""Ponte MQTT ESP32 → Fabric (esp32_direct + esp32_payload_only via relay)."""

from __future__ import annotations

import json
import os
import queue
import subprocess
import threading
import time
from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Any

from fabric_client import FabricConfig, register_edge_observation


@dataclass
class Esp32Observation:
    observation_id: str
    device_id: str
    payload_hash: str
    recorded_at: str
    sign_alg: str
    device_signature: str
    signing_mode: str
    scenario: str
    network: str
    raw: dict[str, Any]

    @classmethod
    def from_payload(cls, data: dict[str, Any]) -> "Esp32Observation":
        rid = data.get("observation_id") or data.get("id") or ""
        recorded = data.get("recorded_at")
        if isinstance(recorded, (int, float)):
            recorded = datetime.fromtimestamp(recorded, tz=timezone.utc).strftime(
                "%Y-%m-%dT%H:%M:%SZ"
            )
        recorded = str(recorded or datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"))
        return cls(
            observation_id=str(rid),
            device_id=str(data.get("device_id") or "esp32-ward-01"),
            payload_hash=str(data.get("payload_hash") or ""),
            recorded_at=recorded,
            sign_alg=str(data.get("signAlg") or ""),
            device_signature=str(data.get("deviceSignature") or ""),
            signing_mode=str(data.get("signing_mode") or "esp32_direct"),
            scenario=str(data.get("scenario") or ""),
            network=str(data.get("network") or "baseline"),
            raw=data,
        )


def effective_signing_mode(obs: Esp32Observation) -> str:
    """Modo efetivo para metadata (fallback C4 sem assinatura on-device)."""
    raw = obs.raw
    if raw.get("sign_ok") is False:
        return "esp32_payload_only"
    if obs.device_signature and obs.sign_alg and raw.get("sign_ok") is not False:
        return obs.signing_mode or "esp32_direct"
    if obs.signing_mode == "esp32_direct" and not obs.device_signature:
        return "esp32_payload_only"
    return obs.signing_mode or "esp32_payload_only"


class MqttObservationQueue:
    """Buffer thread-safe de observações recebidas via MQTT."""

    def __init__(self) -> None:
        self._q: queue.Queue[Esp32Observation] = queue.Queue()

    def push_json(self, payload: str) -> None:
        data = json.loads(payload)
        self._q.put(Esp32Observation.from_payload(data))

    def wait(self, timeout_s: float) -> Esp32Observation | None:
        try:
            return self._q.get(timeout=timeout_s)
        except queue.Empty:
            return None


def _publish_docker(topic: str, payload: str, container: str) -> None:
    subprocess.run(
        ["docker", "exec", container, "mosquitto_pub", "-h", "localhost", "-p", "1883", "-t", topic, "-m", payload],
        check=True,
    )


def run_mqtt_listener(
    host: str,
    port: int,
    topic: str,
    obs_queue: MqttObservationQueue,
    via_docker: bool = False,
    container: str = "iomt-mosquitto",
) -> threading.Thread | None:
    """Inicia listener MQTT; retorna client thread ou None se usar docker sub externo."""

    def on_message(_client: Any, _userdata: Any, msg: Any) -> None:
        obs_queue.push_json(msg.payload.decode("utf-8"))

    client = None
    if not via_docker:
        try:
            import paho.mqtt.client as mqtt  # type: ignore

            client = mqtt.Client()
            client.on_message = on_message
            client.connect(host, port, 60)
            client.subscribe(topic, qos=1)
            client.loop_start()
            return None
        except ImportError:
            pass

    def docker_sub_loop() -> None:
        proc = subprocess.Popen(
            [
                "docker",
                "exec",
                "-i",
                container,
                "mosquitto_sub",
                "-h",
                "localhost",
                "-p",
                "1883",
                "-t",
                topic,
                "-v",
            ],
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
        )
        assert proc.stdout is not None
        for line in proc.stdout:
            # formato mosquitto_sub -v: topic payload
            parts = line.strip().split(" ", 1)
            if len(parts) == 2 and parts[0].startswith("iomt/esp32/"):
                obs_queue.push_json(parts[1])

    th = threading.Thread(target=docker_sub_loop, daemon=True)
    th.start()
    return th


def submit_observation_to_fabric(
    cfg: FabricConfig,
    obs: Esp32Observation,
    relay_mode: str = "mqtt",
) -> tuple[int, dict, str]:
    """Submete ao chaincode; retorna (latency_ms, ledger, effective_signing_mode)."""
    mode = effective_signing_mode(obs)
    lat, ledger = register_edge_observation(
        cfg,
        obs.observation_id,
        obs.device_id,
        obs.payload_hash,
        obs.recorded_at,
        obs.sign_alg,
        obs.device_signature,
        "",
        "",
    )
    if mode == "esp32_direct" and relay_mode:
        # Documentar que o relay MQTT foi usado para tx (paridade experimental)
        _ = relay_mode
    return lat, ledger, mode


def wait_and_submit_one(
    cfg: FabricConfig,
    obs_queue: MqttObservationQueue,
    timeout_s: float = 30.0,
) -> dict[str, Any]:
    obs = obs_queue.wait(timeout_s)
    if not obs:
        raise TimeoutError(f"nenhuma observação MQTT em {timeout_s}s (tópico observation)")
    lat, ledger, mode = submit_observation_to_fabric(cfg, obs)
    return {
        "observation_id": obs.observation_id,
        "signing_mode_effective": mode,
        "signAlg": ledger.get("signAlg") or obs.sign_alg,
        "latency_ms": lat,
        "ledger": ledger,
    }
