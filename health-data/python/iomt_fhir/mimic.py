"""Leitor MIMIC-IV (chartevents) → Observation FHIR."""

from __future__ import annotations

import csv
import gzip
import os
from datetime import datetime
from pathlib import Path
from typing import Iterator

from .models import VITAL_SIGNS, Observation

# chartevents itemid → LOINC
MIMIC_ITEMID_TO_LOINC: dict[int, str] = {
    220045: "8867-4",
    220179: "8480-6",
    220180: "8462-4",
    220210: "9279-1",
    220277: "2708-6",
    223761: "8310-5",
    223762: "8310-5",
}


def _open_csv(path: Path):
    if path.suffix == ".gz":
        return gzip.open(path, "rt", encoding="utf-8", newline="")
    return open(path, encoding="utf-8", newline="")


def find_chartevents(mimic_root: Path) -> Path | None:
    candidates = [
        mimic_root / "icu/chartevents.csv.gz",
        mimic_root / "icu/chartevents.csv",
        mimic_root / "chartevents.csv.gz",
    ]
    for c in candidates:
        if c.is_file():
            return c
    return None


def iter_mimic_observations(
    mimic_root: str | Path,
    *,
    limit: int = 1000,
    item_ids: set[int] | None = None,
) -> Iterator[Observation]:
    """Itera observações a partir de chartevents (amostra limitada)."""
    root = Path(mimic_root)
    path = find_chartevents(root)
    if path is None:
        raise FileNotFoundError(f"chartevents não encontrado em {root}")

    item_ids = item_ids or set(MIMIC_ITEMID_TO_LOINC.keys())
    count = 0

    with _open_csv(path) as f:
        reader = csv.DictReader(f)
        for row in reader:
            try:
                itemid = int(row.get("itemid") or 0)
            except ValueError:
                continue
            if itemid not in item_ids:
                continue
            loinc = MIMIC_ITEMID_TO_LOINC.get(itemid)
            if not loinc:
                continue
            val = row.get("valuenum")
            if val in (None, "", "NaN"):
                continue
            try:
                value = float(val)
            except ValueError:
                continue

            subject_id = row.get("subject_id") or row.get("hadm_id") or "0"
            patient_id = f"mimic-{subject_id}"
            charttime = row.get("charttime") or row.get("storetime") or ""
            try:
                dt = datetime.fromisoformat(charttime.replace(" ", "T"))
                if dt.tzinfo is None:
                    effective = dt.strftime("%Y-%m-%dT%H:%M:%SZ")
                else:
                    effective = dt.astimezone().strftime("%Y-%m-%dT%H:%M:%SZ")
            except ValueError:
                effective = datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ")

            _, unit, _ = VITAL_SIGNS.get(loinc, ("", "", ""))
            uom = (row.get("valueuom") or unit).strip() or unit

            yield Observation(
                id=f"mimic-obs-{subject_id}-{itemid}-{count}",
                loinc=loinc,
                patient_id=patient_id,
                device_id=os.environ.get("IOMT_DEVICE_ID", "device-pi-lab-001"),
                effective_at=effective,
                value=round(value, 2),
                unit=uom,
                data_source="MIMIC",
            )
            count += 1
            if count >= limit:
                break
