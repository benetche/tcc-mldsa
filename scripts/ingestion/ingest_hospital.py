#!/usr/bin/env python3
"""
Ingestão hospitalar FHIR → Fabric (chaincode iomt).
Modos: SYNTHETIC (fixtures) ou MIMIC (MIMIC_DATA_PATH).
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "health-data/python"))

from iomt_fhir.hashutil import fhir_payload_hash  # noqa: E402
from iomt_fhir.models import Observation, build_synthetic_bundle, observations_from_bundle  # noqa: E402
from iomt_fhir.mimic import iter_mimic_observations  # noqa: E402
from iomt_fhir.validate import validate_observation  # noqa: E402

from fabric_client import FabricConfig, register_fhir_observation  # noqa: E402


def load_profile(name: str) -> dict:
    path = ROOT / "benchmarks/scenarios" / f"{name}.yaml"
    return yaml.safe_load(path.read_text(encoding="utf-8"))


def iter_observations(source: str, limit: int | None) -> list[Observation]:
    if source == "MIMIC":
        mimic_path = os.environ.get("MIMIC_DATA_PATH")
        if not mimic_path:
            raise SystemExit("MIMIC_DATA_PATH obrigatório para source=MIMIC")
        obs = list(iter_mimic_observations(mimic_path, limit=limit or 500))
        return obs

    bundle_path = ROOT / "health-data/fixtures/synthetic-bundle.json"
    if not bundle_path.is_file():
        raise SystemExit("fixtures ausentes — rode generate_fixtures.py")
    bundle = json.loads(bundle_path.read_text(encoding="utf-8"))
    out = list(observations_from_bundle(bundle))
    if limit:
        out = out[:limit]
    return out


def main() -> None:
    parser = argparse.ArgumentParser(description="Ingestão FHIR → Fabric")
    parser.add_argument("--profile", default="hospital-low", help="hospital-low | hospital-high")
    parser.add_argument("--source", default=None, help="SYNTHETIC | MIMIC")
    parser.add_argument("--max-records", type=int, default=0, help="0 = ilimitado no perfil")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument(
        "--id-suffix",
        default="",
        help="sufixo único nos IDs (ex.: smoke reexecutável no mesmo ledger)",
    )
    args = parser.parse_args()

    profile = load_profile(args.profile)
    interval_ms = int(profile["interval_ms"])
    burst = int(profile.get("burst_size", 1))
    duration_min = float(profile.get("duration_minutes", 5))
    source = args.source or os.environ.get("IOMT_DATA_SOURCE", "SYNTHETIC")

    cfg = FabricConfig.from_env()
    observations = iter_observations(source, limit=5000)
    if not observations:
        raise SystemExit("nenhuma observação para ingerir")

    deadline = time.time() + duration_min * 60
    sent = 0
    errors = 0
    bytes_total = 0
    latencies: list[int] = []
    idx = 0
    n = len(observations)

    print(
        json.dumps(
            {
                "profile": args.profile,
                "source": source,
                "interval_ms": interval_ms,
                "burst": burst,
                "duration_minutes": duration_min,
                "started_at": datetime.now(timezone.utc).isoformat(),
            }
        )
    )

    while time.time() < deadline:
        for _ in range(burst):
            obs = observations[idx % n]
            idx += 1
            fhir = obs.to_fhir()
            errs = validate_observation(fhir)
            if errs:
                errors += 1
                continue
            canonical = obs.canonical_json()
            phash = fhir_payload_hash(canonical)
            fbytes = len(canonical.encode("utf-8"))
            bytes_total += fbytes

            if args.dry_run:
                sent += 1
                continue

            ledger_id = f"{obs.id}{args.id_suffix}" if args.id_suffix else obs.id
            try:
                lat, ledger = register_fhir_observation(
                    cfg,
                    ledger_id,
                    obs.patient_id,
                    obs.device_id,
                    obs.loinc,
                    obs.value_quantity_str(),
                    obs.effective_at,
                    phash,
                    obs.data_source,
                    fbytes,
                )
                latencies.append(lat)
                sent += 1
                if sent <= 3 or sent % 50 == 0:
                    print(
                        f"  ok id={ledger_id} loinc={obs.loinc} latency_ms={lat} "
                        f"ledger_patient={ledger.get('patientId', '')}"
                    )
            except subprocess.CalledProcessError as ex:
                errors += 1
                print(f"  erro invoke: {ex.stderr.decode() if ex.stderr else ex}", file=sys.stderr)

            if args.max_records and sent >= args.max_records:
                break
        if args.max_records and sent >= args.max_records:
            break
        time.sleep(interval_ms / 1000.0)

    rate = sent / max(duration_min, 0.01) / 60.0
    summary = {
        "sent": sent,
        "errors": errors,
        "bytes_total": bytes_total,
        "avg_payload_bytes": round(bytes_total / sent, 1) if sent else 0,
        "records_per_min": round(rate * 60, 2),
        "latency_ms_avg": round(sum(latencies) / len(latencies), 1) if latencies else 0,
        "latency_ms_p95": sorted(latencies)[int(len(latencies) * 0.95)] if latencies else 0,
    }
    print(json.dumps({"summary": summary}, indent=2))


if __name__ == "__main__":
    main()
