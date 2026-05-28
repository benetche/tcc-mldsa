"""Validação mínima de Observation FHIR (sem dependência de servidor FHIR)."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

REQUIRED_TOP = {"resourceType", "id", "status", "code", "subject", "effectiveDateTime", "valueQuantity"}


def validate_observation(obs: dict[str, Any]) -> list[str]:
    """Retorna lista de erros (vazia = OK)."""
    errors: list[str] = []
    if obs.get("resourceType") != "Observation":
        errors.append("resourceType deve ser Observation")
    for key in REQUIRED_TOP:
        if key not in obs:
            errors.append(f"campo obrigatório ausente: {key}")
    coding = obs.get("code", {}).get("coding", [])
    if not coding or not coding[0].get("code"):
        errors.append("code.coding[0].code obrigatório")
    vq = obs.get("valueQuantity", {})
    if "value" not in vq:
        errors.append("valueQuantity.value obrigatório")
    ref = obs.get("subject", {}).get("reference", "")
    if not ref.startswith("Patient/"):
        errors.append("subject.reference deve ser Patient/...")
    return errors


def validate_observation_file(path: Path) -> list[str]:
    data = json.loads(path.read_text(encoding="utf-8"))
    if data.get("resourceType") == "Bundle":
        all_errs: list[str] = []
        for i, entry in enumerate(data.get("entry", [])):
            res = entry.get("resource", {})
            if res.get("resourceType") != "Observation":
                continue
            errs = validate_observation(res)
            for e in errs:
                all_errs.append(f"entry[{i}]: {e}")
        return all_errs
    return validate_observation(data)
