import json

import httpx

from config import settings
from models.schemas import RecommendationInsight, RecommendationsResult


def generate_recommendations(analysis_prompt: str) -> RecommendationsResult:
    base_url = settings.jac_service_url.strip()
    if not base_url:
        raise RuntimeError("Jac recommendations backend is not configured")

    walker_url = f"{base_url.rstrip('/')}/walker/{settings.jac_recommendations_walker_name}"
    payload = {
        "analysis_prompt": analysis_prompt,
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
        return RecommendationsResult(
            **{
                "generated_at": raw["generated_at"],
                "menu_delta": raw.get("menu_delta", []),
                "insights": [RecommendationInsight(**ins) for ins in raw.get("insights", [])],
                "summary_text": raw.get("summary_text", ""),
            }
        )
    except (KeyError, TypeError, ValueError) as exc:
        raise ValueError("Jac service returned an invalid recommendations payload") from exc
