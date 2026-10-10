import json

import httpx

from config import settings
from models.schemas import HomeContent


def get_home_content() -> HomeContent:
    base_url = settings.jac_service_url.strip()
    if not base_url:
        raise RuntimeError("Jac home backend is not configured")

    walker_url = f"{base_url.rstrip('/')}/walker/{settings.jac_home_walker_name}"

    try:
        with httpx.Client(timeout=45) as client:
            resp = client.post(walker_url, json={})
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
        return HomeContent(**raw)
    except (TypeError, ValueError) as exc:
        raise ValueError("Jac service returned an invalid home payload") from exc
