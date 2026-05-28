#!/usr/bin/env python3
"""Valida fixtures FHIR (schema + regras mínimas)."""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "health-data/python"))

from iomt_fhir.validate import validate_observation_file  # noqa: E402

try:
    import jsonschema
except ImportError:
    jsonschema = None  # type: ignore


def main() -> None:
    fixtures = ROOT / "health-data/fixtures"
    schema_path = ROOT / "health-data/schemas/fhir-observation-minimal.schema.json"
    bundle = fixtures / "synthetic-bundle.json"
    if not bundle.is_file():
        print(f"ERRO: rode generate_fixtures.py primeiro ({bundle})", file=sys.stderr)
        sys.exit(1)

    errs = validate_observation_file(bundle)
    if errs:
        print("Erros de validação:", file=sys.stderr)
        for e in errs:
            print(f"  - {e}", file=sys.stderr)
        sys.exit(1)

    if jsonschema:
        schema = json.loads(schema_path.read_text(encoding="utf-8"))
        data = json.loads(bundle.read_text(encoding="utf-8"))
        for i, entry in enumerate(data.get("entry", [])):
            res = entry.get("resource", {})
            if res.get("resourceType") != "Observation":
                continue
            try:
                jsonschema.validate(res, schema)
            except jsonschema.ValidationError as ex:
                print(f"schema entry[{i}]: {ex.message}", file=sys.stderr)
                sys.exit(1)

    print(f"OK: {bundle} válido")


if __name__ == "__main__":
    main()
