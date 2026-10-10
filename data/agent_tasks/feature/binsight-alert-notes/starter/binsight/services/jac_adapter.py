import base64
import json
from pathlib import Path

import httpx

from config import settings
from models.schemas import WasteItem, WasteSummary


# Additional walkers exposed by the Jac extensions layer. The vision service
# only calls AnalyzeWaste today, but these are the graph walkers we expect to
# chain into the analysis pipeline as the migration progresses.
RELATED_EXTENSION_WALKERS = (
    "AttachWasteRecord",
    "AddLineItem",
    "SummarizeRecord",
    "SuggestSeverityFromTotals",
    "MatchLineToMenuItem",
)


def is_configured() -> bool:
    return bool(settings.jac_service_url.strip())


def analyze_waste(
    image_path: Path,
    menu_items: list[str],
    constant_items: list[str],
) -> tuple[list[WasteItem], WasteSummary, str]:
    base_url = settings.jac_service_url.strip()
    if not base_url:
        raise RuntimeError("Jac analysis backend is not configured")

    walker_url = f"{base_url.rstrip('/')}/walker/{settings.jac_walker_name}"
    image_bytes = image_path.read_bytes()

    payload = {
        "image_path": str(image_path),
        "image_b64": base64.standard_b64encode(image_bytes).decode("utf-8"),
        "image_media_type": _detect_media_type(image_path),
        "current_menu": menu_items,
        "constant_items": constant_items,
    }

    try:
        with httpx.Client(timeout=90) as client:
            resp = client.post(walker_url, json=payload)
    except httpx.HTTPError as exc:
        raise RuntimeError(f"Jac service request failed: {exc}") from exc

    if resp.status_code != 200:
        raise RuntimeError(f"Jac service error {resp.status_code}: {resp.text}")

    try:
        envelope = resp.json()
        raw = envelope["data"]["reports"][0]
        if isinstance(raw, str):
            raw = json.loads(raw)
    except (KeyError, IndexError, TypeError, json.JSONDecodeError) as exc:
        raise ValueError("Jac service returned an invalid response envelope") from exc

    try:
        items = [WasteItem(**item) for item in raw["items"]]
        summary = WasteSummary(**raw["summary"])
    except (KeyError, TypeError, ValueError) as exc:
        raise ValueError("Jac service returned an invalid analysis payload") from exc

    notes = raw.get("notes", "")
    return items, summary, notes


def _detect_media_type(image_path: Path) -> str:
    suffix = image_path.suffix.lower()
    media_types = {
        ".jpg": "image/jpeg",
        ".jpeg": "image/jpeg",
        ".png": "image/png",
        ".gif": "image/gif",
        ".webp": "image/webp",
    }
    return media_types.get(suffix, "image/jpeg")
