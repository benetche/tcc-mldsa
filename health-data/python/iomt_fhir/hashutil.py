"""Hash de payload FHIR para o ledger."""

from __future__ import annotations

import hashlib
import json
from typing import Any


def fhir_payload_hash(fhir_obj: dict[str, Any] | str) -> str:
    """Retorna sha256:<hex> do JSON canônico."""
    if isinstance(fhir_obj, str):
        data = fhir_obj.encode("utf-8")
    else:
        data = json.dumps(fhir_obj, sort_keys=True, separators=(",", ":")).encode("utf-8")
    digest = hashlib.sha256(data).hexdigest()
    return f"sha256:{digest}"
