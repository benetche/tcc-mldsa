#!/usr/bin/env python3
"""
Runner de benchmark P4 (um cenário × uma carga).

Reaproveita a ingestão FHIR do Pilar 3 (`scripts/ingestion`) e o pacote
`iomt_fhir` para enviar observações ao chaincode `iomt`, medindo latência
end-to-end por transação, TPS, bytes de payload e recursos (CPU/RAM).

Saída por execução em `benchmarks/results/<run_id>/`:
  - metadata.json   (cenário, signing_mode, commit, versões, resumo)
  - metrics.csv     (uma linha por transação medida)
  - resources.csv   (amostras CPU%/RAM ao longo da execução)

Cenários ESP32 (device=esp32) sem bridge configurada geram um resultado
`hardware_pending` documentado — nunca são omitidos (robustez C1–C4).
"""

from __future__ import annotations

import argparse
import json
import os
import platform
import subprocess
import sys
import threading
import time
from datetime import datetime, timezone
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "health-data/python"))
sys.path.insert(0, str(ROOT / "scripts/ingestion"))

from iomt_fhir.hashutil import fhir_payload_hash  # noqa: E402
from iomt_fhir.models import (  # noqa: E402
    Observation,
    build_synthetic_bundle,
    observations_from_bundle,
)
from iomt_fhir.mimic import iter_mimic_observations  # noqa: E402
from iomt_fhir.validate import validate_observation  # noqa: E402


# --------------------------------------------------------------------------
# Estatística (sem numpy — manter dependências mínimas no Pi)
# --------------------------------------------------------------------------
def percentile(values: list[float], pct: float) -> float:
    if not values:
        return 0.0
    ordered = sorted(values)
    k = (len(ordered) - 1) * (pct / 100.0)
    lo = int(k)
    hi = min(lo + 1, len(ordered) - 1)
    frac = k - lo
    return ordered[lo] + (ordered[hi] - ordered[lo]) * frac


def mean(values: list[float]) -> float:
    return sum(values) / len(values) if values else 0.0


# --------------------------------------------------------------------------
# Amostragem de recursos (CPU% via /proc/stat, RAM via /proc/meminfo)
# --------------------------------------------------------------------------
class ResourceSampler(threading.Thread):
    def __init__(self, interval_s: float = 1.0):
        super().__init__(daemon=True)
        self.interval_s = interval_s
        self._stop_evt = threading.Event()
        self.samples: list[dict[str, float]] = []

    @staticmethod
    def _cpu_times() -> tuple[int, int]:
        try:
            with open("/proc/stat", encoding="utf-8") as fh:
                parts = fh.readline().split()[1:]
            nums = [int(x) for x in parts]
            idle = nums[3] + (nums[4] if len(nums) > 4 else 0)
            return sum(nums), idle
        except OSError:
            return 0, 0

    @staticmethod
    def _mem() -> tuple[int, int]:
        total = avail = 0
        try:
            with open("/proc/meminfo", encoding="utf-8") as fh:
                for line in fh:
                    if line.startswith("MemTotal:"):
                        total = int(line.split()[1])
                    elif line.startswith("MemAvailable:"):
                        avail = int(line.split()[1])
                    if total and avail:
                        break
        except OSError:
            pass
        return total, avail

    @staticmethod
    def _load1() -> float:
        try:
            with open("/proc/loadavg", encoding="utf-8") as fh:
                return float(fh.readline().split()[0])
        except OSError:
            return 0.0

    def run(self) -> None:
        prev_total, prev_idle = self._cpu_times()
        while not self._stop_evt.wait(self.interval_s):
            total, idle = self._cpu_times()
            dt = total - prev_total
            di = idle - prev_idle
            cpu = 100.0 * (1.0 - di / dt) if dt > 0 else 0.0
            prev_total, prev_idle = total, idle
            mem_total, mem_avail = self._mem()
            self.samples.append(
                {
                    "ts": time.time(),
                    "cpu_percent": round(cpu, 2),
                    "mem_used_mb": round((mem_total - mem_avail) / 1024, 1),
                    "mem_total_mb": round(mem_total / 1024, 1),
                    "load_1m": self._load1(),
                }
            )

    def stop(self) -> list[dict[str, float]]:
        self._stop_evt.set()
        self.join(timeout=self.interval_s * 2)
        return self.samples


# --------------------------------------------------------------------------
# Fonte de observações
# --------------------------------------------------------------------------
def load_observations(source: str, limit: int) -> list[Observation]:
    if source == "MIMIC":
        mimic_path = os.environ.get("MIMIC_DATA_PATH")
        if not mimic_path:
            raise SystemExit("MIMIC_DATA_PATH obrigatório para source=MIMIC")
        return list(iter_mimic_observations(mimic_path, limit=limit))
    return list(observations_from_bundle(build_synthetic_bundle()))[:limit] or list(
        observations_from_bundle(build_synthetic_bundle())
    )


def git_commit() -> str:
    try:
        out = subprocess.run(
            ["git", "rev-parse", "--short", "HEAD"],
            cwd=ROOT,
            capture_output=True,
            text=True,
            check=True,
        )
        return out.stdout.strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return "unknown"


def fabric_version() -> str:
    samples = Path(os.environ.get("FABRIC_SAMPLES_DIR", ROOT / "fabric-samples"))
    peer = samples / "bin" / "peer"
    if peer.is_file():
        try:
            out = subprocess.run(
                [str(peer), "version"], capture_output=True, text=True, check=True
            )
            for line in out.stdout.splitlines():
                if "Version:" in line:
                    return line.split("Version:")[1].strip()
        except (subprocess.CalledProcessError, FileNotFoundError):
            pass
    return os.environ.get("FABRIC_VERSION", "unknown")


# --------------------------------------------------------------------------
# ESP32 via ponte MQTT (C3/C4)
# --------------------------------------------------------------------------
def _run_esp32_mqtt_benchmark(
    meta: dict,
    scenario: dict,
    load_profile: dict,
    *,
    network: str,
    warmup_tx: int,
    sample_tx: int,
    out_dir: Path,
    id_suffix: str,
    dry_run: bool,
    interval_ms: int,
) -> dict:
    from esp32_mqtt_bridge import MqttObservationQueue, run_mqtt_listener, submit_observation_to_fabric
    from fabric_client import FabricConfig

    device_id = os.environ.get("IOMT_DEVICE_ID", "esp32-ward-01")
    mqtt_host = os.environ.get("MQTT_HOST", "localhost")
    mqtt_port = int(os.environ.get("MQTT_PORT", "1883"))
    topic = f"iomt/esp32/{device_id}/observation"
    via_docker = os.environ.get("MQTT_VIA_DOCKER", "") == "1"

    meta["bridge"] = "mqtt"
    meta["relay"] = "mqtt"
    meta["mqtt_topic"] = topic
    meta["signing_mode_fallback"] = scenario.get("signing_mode_fallback", "")

    obs_q = MqttObservationQueue()
    run_mqtt_listener(mqtt_host, mqtt_port, topic, obs_q, via_docker=via_docker)

    cfg = FabricConfig.from_env()
    sampler = ResourceSampler(interval_s=1.0)
    if not dry_run:
        sampler.start()

    metrics_fh = (out_dir / "metrics.csv").open("w", encoding="utf-8")
    metrics_fh.write("tx_index,timestamp,latency_ms,ok,payload_bytes,patient_id,loinc\n")

    latencies: list[float] = []
    sent = errors = 0
    total_tx = warmup_tx + sample_tx
    # ESP publica a cada 1–5s (firmware); YAML hospital-low=500ms não se aplica ao dispositivo
    timeout_s = float(os.environ.get("MQTT_WAIT_TIMEOUT", "25"))
    timeout_s = max(timeout_s, interval_ms / 1000.0 * 3, 15.0)
    effective_modes: list[str] = []

    for i in range(total_tx):
        is_warmup = i < warmup_tx
        obs = obs_q.wait(timeout_s)
        if obs is None:
            errors += 1
            continue
        if dry_run:
            if not is_warmup:
                latencies.append(0.0)
                sent += 1
            continue
        try:
            lat, ledger, eff_mode = submit_observation_to_fabric(cfg, obs, relay_mode="mqtt")
            effective_modes.append(eff_mode)
            ts = datetime.now(timezone.utc).isoformat()
            if not is_warmup:
                latencies.append(float(lat))
                sent += 1
                phash_len = len(obs.payload_hash.encode("utf-8"))
                metrics_fh.write(f"{i},{ts},{lat},1,{phash_len},esp32,edge\n")
        except subprocess.CalledProcessError:
            if not is_warmup:
                errors += 1

    metrics_fh.close()
    sampler.stop()
    resources = sampler.samples
    if resources:
        with (out_dir / "resources.csv").open("w", encoding="utf-8") as rf:
            rf.write("timestamp,cpu_percent,mem_used_mb,mem_total_mb,load_1m\n")
            for s in resources:
                rf.write(
                    f"{s['ts']},{s['cpu_percent']:.2f},{s['mem_used_mb']:.2f},"
                    f"{s['mem_total_mb']:.2f},{s.get('load_1m', 0):.2f}\n"
                )

    meta["signing_mode_effective"] = effective_modes[-1] if effective_modes else meta.get("signing_mode")
    meta["status"] = "ok" if sent > 0 else "error"
    meta["finished_at"] = datetime.now(timezone.utc).isoformat()
    success = sent / max(sent + errors, 1)
    meta["summary"] = {
        "sent": sent,
        "errors": errors,
        "success_rate": round(success, 4),
        "latency_ms_avg": round(mean(latencies), 2) if latencies else None,
        "latency_ms_p50": round(percentile(latencies, 50), 2) if latencies else None,
        "latency_ms_p95": round(percentile(latencies, 95), 2) if latencies else None,
        "tps": round(sent / max((latencies and sum(latencies) / 1000.0) or 1, 1), 4)
        if latencies
        else None,
        "avg_payload_bytes": None,
    }
    (out_dir / "metadata.json").write_text(json.dumps(meta, indent=2), encoding="utf-8")
    print(
        f"[{meta['scenario_id']}/{meta['load_profile']}] ESP32/MQTT sent={sent} err={errors} "
        f"p95={meta['summary']['latency_ms_p95']}ms → {out_dir}"
    )
    return meta


# --------------------------------------------------------------------------
# Execução de um cenário × carga
# --------------------------------------------------------------------------
def run_benchmark(
    scenario: dict,
    load_profile: dict,
    *,
    network: str,
    source: str,
    warmup_tx: int,
    sample_tx: int,
    out_dir: Path,
    id_suffix: str,
    dry_run: bool,
) -> dict:
    out_dir.mkdir(parents=True, exist_ok=True)
    device = scenario.get("device", "raspberry-pi")
    scenario_id = scenario.get("scenario_id", "?")
    signing_mode = scenario.get("signing_mode", "")
    interval_ms = int(load_profile.get("interval_ms", 500))
    burst = int(load_profile.get("burst_size", 1))

    meta: dict = {
        "run_id": out_dir.name,
        "scenario_id": scenario_id,
        "network": network,
        "device": device,
        "signing_mode": signing_mode,
        "load_profile": load_profile.get("profile", "?"),
        "interval_ms": interval_ms,
        "burst_size": burst,
        "warmup_transactions": warmup_tx,
        "sample_transactions": sample_tx,
        "source": source,
        "git_commit": git_commit(),
        "fabric_version": fabric_version(),
        "host": platform.node(),
        "started_at": datetime.now(timezone.utc).isoformat(),
        "dry_run": dry_run,
    }

    # ESP32 sem bridge: resultado documentado, não omitido (matriz C1–C4)
    bridge = os.environ.get("IOMT_ESP32_BRIDGE")
    if device == "esp32" and not bridge:
        meta.update(
            {
                "status": "hardware_pending",
                "note": (
                    "ESP32-D ausente: firmware/assinatura on-device pendente. "
                    "Defina IOMT_ESP32_BRIDGE (mqtt|serial|http) quando o hardware "
                    "estiver disponível. Ver cenarios-experimentais.md (signing_mode)."
                ),
                "signing_mode_fallback": scenario.get("signing_mode_fallback", ""),
                "finished_at": datetime.now(timezone.utc).isoformat(),
                "summary": {
                    "sent": 0,
                    "errors": 0,
                    "success_rate": None,
                    "latency_ms_avg": None,
                    "latency_ms_p50": None,
                    "latency_ms_p95": None,
                    "tps": None,
                    "avg_payload_bytes": None,
                },
            }
        )
        (out_dir / "metadata.json").write_text(
            json.dumps(meta, indent=2), encoding="utf-8"
        )
        (out_dir / "metrics.csv").write_text(
            "tx_index,timestamp,latency_ms,ok,payload_bytes,patient_id,loinc\n",
            encoding="utf-8",
        )
        print(f"[{scenario_id}/{meta['load_profile']}] hardware_pending (ESP32) → {out_dir}")
        return meta

    # Cenários ESP32: observações via MQTT (assinatura no dispositivo + relay Fabric)
    if device == "esp32" and bridge == "mqtt":
        return _run_esp32_mqtt_benchmark(
            meta,
            scenario,
            load_profile,
            network=network,
            warmup_tx=warmup_tx,
            sample_tx=sample_tx,
            out_dir=out_dir,
            id_suffix=id_suffix,
            dry_run=dry_run,
            interval_ms=interval_ms,
        )

    # Cenários Pi/host: ingestão real via peer CLI
    from fabric_client import FabricConfig, register_fhir_observation

    cfg = FabricConfig.from_env()
    observations = load_observations(source, limit=max(sample_tx + warmup_tx, 30))
    if not observations:
        raise SystemExit("nenhuma observação disponível")

    sampler = ResourceSampler(interval_s=1.0)
    if not dry_run:
        sampler.start()

    metrics_fh = (out_dir / "metrics.csv").open("w", encoding="utf-8")
    metrics_fh.write("tx_index,timestamp,latency_ms,ok,payload_bytes,patient_id,loinc\n")

    latencies: list[float] = []
    payload_sizes: list[int] = []
    sent = errors = 0
    n = len(observations)
    total_tx = warmup_tx + sample_tx
    t_start = time.time()

    for i in range(total_tx):
        obs = observations[i % n]
        is_warmup = i < warmup_tx
        tx_id = f"{obs.id}_{id_suffix}_{i:05d}"
        canonical = obs.canonical_json()
        phash = fhir_payload_hash(canonical)
        fbytes = len(canonical.encode("utf-8"))

        verr = validate_observation(obs.to_fhir())
        if verr:
            errors += 1
            continue

        if dry_run:
            if not is_warmup:
                latencies.append(0.0)
                payload_sizes.append(fbytes)
            continue

        try:
            lat, ledger = register_fhir_observation(
                cfg,
                tx_id,
                obs.patient_id,
                obs.device_id,
                obs.loinc,
                obs.value_quantity_str(),
                obs.effective_at,
                phash,
                obs.data_source,
                fbytes,
            )
            ts = datetime.now(timezone.utc).isoformat()
            if not is_warmup:
                latencies.append(float(lat))
                payload_sizes.append(fbytes)
                sent += 1
                metrics_fh.write(
                    f"{i},{ts},{lat},1,{fbytes},{obs.patient_id},{obs.loinc}\n"
                )
        except subprocess.CalledProcessError as ex:
            if not is_warmup:
                errors += 1
                ts = datetime.now(timezone.utc).isoformat()
                metrics_fh.write(f"{i},{ts},,0,{fbytes},{obs.patient_id},{obs.loinc}\n")
            err = ex.stderr.decode() if ex.stderr else str(ex)
            print(f"  erro tx {i}: {err.strip()[:120]}", file=sys.stderr)

        if interval_ms and not is_warmup and (i % burst == burst - 1):
            time.sleep(interval_ms / 1000.0)

    metrics_fh.close()
    elapsed = time.time() - t_start
    resource_samples = sampler.stop() if not dry_run else []

    if resource_samples:
        with (out_dir / "resources.csv").open("w", encoding="utf-8") as rfh:
            rfh.write("timestamp,cpu_percent,mem_used_mb,mem_total_mb,load_1m\n")
            for s in resource_samples:
                rfh.write(
                    f"{s['ts']},{s['cpu_percent']},{s['mem_used_mb']},"
                    f"{s['mem_total_mb']},{s['load_1m']}\n"
                )

    measured = sent if not dry_run else len(payload_sizes)
    tps = round(sent / elapsed, 3) if (elapsed > 0 and sent) else 0.0
    cpu_avg = mean([s["cpu_percent"] for s in resource_samples]) if resource_samples else None
    mem_avg = mean([s["mem_used_mb"] for s in resource_samples]) if resource_samples else None

    meta.update(
        {
            "finished_at": datetime.now(timezone.utc).isoformat(),
            "elapsed_s": round(elapsed, 2),
            "status": "ok" if (measured and errors == 0) else ("partial" if measured else "error"),
            "summary": {
                "sent": sent,
                "errors": errors,
                "success_rate": round(sent / (sent + errors), 4) if (sent + errors) else None,
                "latency_ms_avg": round(mean(latencies), 2) if latencies else None,
                "latency_ms_p50": round(percentile(latencies, 50), 2) if latencies else None,
                "latency_ms_p95": round(percentile(latencies, 95), 2) if latencies else None,
                "tps": tps,
                "avg_payload_bytes": round(mean([float(x) for x in payload_sizes]), 1)
                if payload_sizes
                else None,
                "cpu_percent_avg": round(cpu_avg, 2) if cpu_avg is not None else None,
                "mem_used_mb_avg": round(mem_avg, 1) if mem_avg is not None else None,
            },
        }
    )
    (out_dir / "metadata.json").write_text(json.dumps(meta, indent=2), encoding="utf-8")
    s = meta["summary"]
    print(
        f"[{scenario_id}/{meta['load_profile']}] sent={s['sent']} err={s['errors']} "
        f"p95={s['latency_ms_p95']}ms tps={s['tps']} cpu={s['cpu_percent_avg']}% → {out_dir}"
    )
    return meta


def main() -> None:
    ap = argparse.ArgumentParser(description="Runner de benchmark P4 (1 cenário × 1 carga)")
    ap.add_argument("--scenario-file", required=True)
    ap.add_argument("--load-file", required=True)
    ap.add_argument("--network", default=None, help="baseline | mldsa (default = do cenário)")
    ap.add_argument("--source", default=os.environ.get("IOMT_DATA_SOURCE", "SYNTHETIC"))
    ap.add_argument("--warmup", type=int, default=None)
    ap.add_argument("--samples", type=int, default=None, help="transações medidas (≥30 p/ robustez)")
    ap.add_argument("--out-dir", required=True)
    ap.add_argument("--id-suffix", default=str(int(time.time())))
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    scenario = yaml.safe_load(Path(args.scenario_file).read_text(encoding="utf-8"))
    load_profile = yaml.safe_load(Path(args.load_file).read_text(encoding="utf-8"))
    network = args.network or scenario.get("network", "baseline")
    warmup = args.warmup if args.warmup is not None else int(scenario.get("warmup_transactions", 20))
    samples = args.samples if args.samples is not None else int(scenario.get("repetitions", 30))

    os.environ["FABRIC_NETWORK"] = network
    os.environ.setdefault("REPO_ROOT", str(ROOT))

    run_benchmark(
        scenario,
        load_profile,
        network=network,
        source=args.source,
        warmup_tx=warmup,
        sample_tx=samples,
        out_dir=Path(args.out_dir),
        id_suffix=args.id_suffix,
        dry_run=args.dry_run,
    )


if __name__ == "__main__":
    main()
