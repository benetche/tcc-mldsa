"""Modelos FHIR R4 mínimos (Patient, Device, Observation)."""

from __future__ import annotations

import json
import random
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from typing import Any, Iterator

# LOINC → (display, unit, ucum_code)
VITAL_SIGNS = {
    "8867-4": ("Heart rate", "/min", "/min"),
    "2708-6": ("Oxygen saturation", "%", "%"),
    "8480-6": ("Systolic blood pressure", "mmHg", "mm[Hg]"),
    "8462-4": ("Diastolic blood pressure", "mmHg", "mm[Hg]"),
    "9279-1": ("Respiratory rate", "/min", "/min"),
}


@dataclass
class Patient:
    resource_type: str = "Patient"
    id: str = ""
    gender: str = "unknown"
    data_source: str = "SYNTHETIC"

    def to_fhir(self) -> dict[str, Any]:
        return {
            "resourceType": self.resource_type,
            "id": self.id,
            "meta": {"tag": [{"code": self.data_source}]},
            "identifier": [{"system": "https://tcc-iomt.lab/patient", "value": self.id}],
            "gender": self.gender,
        }


@dataclass
class Device:
    resource_type: str = "Device"
    id: str = "device-pi-lab-001"
    patient_id: str = ""

    def to_fhir(self) -> dict[str, Any]:
        out: dict[str, Any] = {
            "resourceType": self.resource_type,
            "id": self.id,
            "type": {
                "coding": [
                    {
                        "system": "http://snomed.info/sct",
                        "code": "706172005",
                        "display": "General purpose vital signs monitor",
                    }
                ]
            },
        }
        if self.patient_id:
            out["patient"] = {"reference": f"Patient/{self.patient_id}"}
        return out


@dataclass
class Observation:
    resource_type: str = "Observation"
    id: str = ""
    status: str = "final"
    loinc: str = "8867-4"
    patient_id: str = ""
    device_id: str = "device-pi-lab-001"
    effective_at: str = ""
    value: float = 0.0
    unit: str = "/min"
    data_source: str = "SYNTHETIC"

    def to_fhir(self) -> dict[str, Any]:
        display, default_unit, ucum = VITAL_SIGNS.get(self.loinc, ("Vital sign", self.unit, self.unit))
        unit = self.unit or default_unit
        return {
            "resourceType": self.resource_type,
            "id": self.id,
            "status": self.status,
            "meta": {"tag": [{"code": self.data_source}]},
            "category": [
                {
                    "coding": [
                        {
                            "system": "http://terminology.hl7.org/CodeSystem/observation-category",
                            "code": "vital-signs",
                            "display": "Vital Signs",
                        }
                    ]
                }
            ],
            "code": {
                "coding": [
                    {
                        "system": "http://loinc.org",
                        "code": self.loinc,
                        "display": display,
                    }
                ]
            },
            "subject": {"reference": f"Patient/{self.patient_id}"},
            "effectiveDateTime": self.effective_at,
            "valueQuantity": {
                "value": self.value,
                "unit": unit,
                "system": "http://unitsofmeasure.org",
                "code": ucum,
            },
            "device": {"reference": f"Device/{self.device_id}"},
        }

    def canonical_json(self) -> str:
        return json.dumps(self.to_fhir(), sort_keys=True, separators=(",", ":"))

    def value_quantity_str(self) -> str:
        return f"{self.value} {self.unit}"


def build_synthetic_bundle(
    *,
    seed: int = 42,
    n_patients: int = 3,
    observations_per_patient: int = 5,
    start: datetime | None = None,
) -> dict[str, Any]:
    """Gera bundle FHIR sintético determinístico."""
    rng = random.Random(seed)
    start = start or datetime(2026, 1, 15, 8, 0, tzinfo=timezone.utc)
    entries: list[dict[str, Any]] = []
    loincs = list(VITAL_SIGNS.keys())

    for p in range(n_patients):
        pid = f"synth-patient-{p+1:03d}"
        gender = rng.choice(["male", "female", "unknown"])
        patient = Patient(id=pid, gender=gender, data_source="SYNTHETIC")
        entries.append({"resource": patient.to_fhir()})

        device = Device(id=f"device-pi-ward-{p+1}", patient_id=pid)
        entries.append({"resource": device.to_fhir()})

        hr = 72.0 + rng.uniform(-5, 5)
        for o in range(observations_per_patient):
            loinc = loincs[o % len(loincs)]
            _, unit, _ = VITAL_SIGNS[loinc]
            if loinc == "8867-4":
                hr = max(40, min(180, hr + rng.uniform(-3, 3)))
                val = hr
            elif loinc == "2708-6":
                val = max(85, min(100, 97 + rng.uniform(-2, 2)))
            elif loinc.startswith("84"):
                val = 110 + rng.uniform(-15, 15) if loinc == "8480-6" else 70 + rng.uniform(-10, 10)
            else:
                val = 16 + rng.uniform(-2, 2)

            ts = start + timedelta(seconds=o * 60 + p * 300)
            obs = Observation(
                id=f"synth-obs-{p+1:03d}-{o+1:03d}",
                loinc=loinc,
                patient_id=pid,
                device_id=device.id,
                effective_at=ts.strftime("%Y-%m-%dT%H:%M:%SZ"),
                value=round(val, 2),
                unit=unit,
                data_source="SYNTHETIC",
            )
            entries.append({"resource": obs.to_fhir()})

    return {
        "resourceType": "Bundle",
        "type": "collection",
        "meta": {"tag": [{"code": "SYNTHETIC"}]},
        "entry": entries,
    }


def observations_from_bundle(bundle: dict[str, Any]) -> Iterator[Observation]:
    """Extrai Observation do bundle."""
    for entry in bundle.get("entry", []):
        res = entry.get("resource", {})
        if res.get("resourceType") != "Observation":
            continue
        code = res.get("code", {}).get("coding", [{}])[0]
        vq = res.get("valueQuantity", {})
        subject = res.get("subject", {}).get("reference", "")
        patient_id = subject.split("/")[-1] if "/" in subject else subject
        device_ref = res.get("device", {}).get("reference", "device-pi-lab-001")
        device_id = device_ref.split("/")[-1] if "/" in device_ref else device_ref
        tag = (res.get("meta") or {}).get("tag") or [{}]
        yield Observation(
            id=res["id"],
            loinc=code.get("code", ""),
            patient_id=patient_id,
            device_id=device_id,
            effective_at=res.get("effectiveDateTime", ""),
            value=float(vq.get("value", 0)),
            unit=vq.get("unit", ""),
            data_source=tag[0].get("code", "SYNTHETIC"),
        )
