#!/usr/bin/env python3
"""Gera fixtures FHIR sintéticas em health-data/fixtures/."""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "health-data/python"))

from iomt_fhir.models import build_synthetic_bundle  # noqa: E402


def main() -> None:
    out_dir = ROOT / "health-data/fixtures"
    out_dir.mkdir(parents=True, exist_ok=True)
    bundle = build_synthetic_bundle(seed=42, n_patients=3, observations_per_patient=5)
    path = out_dir / "synthetic-bundle.json"
    path.write_text(json.dumps(bundle, indent=2), encoding="utf-8")
    print(f"OK: {path} ({len(bundle['entry'])} resources)")


if __name__ == "__main__":
    main()
