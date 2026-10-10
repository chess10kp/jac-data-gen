import json
from datetime import datetime, timezone

from config import settings
from models.schemas import AnalysisRecord, RecommendationInsight, RecommendationsResult
from services import jac_recommender_adapter, llm_provider

RECOMMENDATION_MAX_TOKENS = 2500

SYSTEM_PROMPT = """You are a food waste reduction advisor for university dining halls.
You will be given structured waste analysis data from one or more bin scans. Each scan lists the specific food items that were actually detected in the waste bin, their weight in ounces, how much of a serving was wasted, their cost, and whether the waste was avoidable.
Your job is to generate concise, actionable recommendations for dining hall managers based on WHAT WAS ACTUALLY DETECTED IN THE BIN.

Respond ONLY with valid JSON (no markdown, no backticks) in this exact format:
{
  "menu_delta": ["observation about what was wasted vs. not wasted"],
  "insights": [
    {
      "priority": "high" | "medium" | "low",
      "action": "specific actionable change",
      "rationale": "data-driven reason citing the specific food item and weight/cost"
    }
  ],
  "summary_text": "2-3 sentence narrative summary of findings"
}

Rules:
- EVERY insight MUST reference specific food items that appear in the detected-waste list, with their actual weights or costs from the data.
- Do NOT recommend changes to menu items that were not actually detected in the bins.
- Do NOT invent foods, quantities, or costs that are not in the provided data.
- If the menu lists an item but it was not detected as waste, DO NOT recommend changing it — it was not wasted.
- Prioritize insights that would reduce the heaviest avoidable items first (by weight or cost).
- Be specific and cite numbers from the data (e.g. "Brown rice: 12.3 oz wasted (~80% of serving) at $1.48 — reduce portion size by 25%").
- If a detected item is not on the menu list, you may still recommend action on it (dining halls waste items beyond the posted menu).
- Limit to 5 insights maximum.
- Keep each action under 28 words.
- Keep each rationale under 45 words.
- Keep summary_text under 45 words."""


def build_recommendation_prompt(records: list[AnalysisRecord]) -> str:
    parts = [f"Number of waste scans analyzed: {len(records)}\n"]

    all_menu_items: set[str] = set()
    for r in records:
        all_menu_items.update(r.menu_items)

    parts.append(f"Menu items served: {', '.join(sorted(all_menu_items)) or 'Not provided'}\n")

    # Aggregated detected-item view across all scans — this is the ground truth.
    aggregate: dict[str, dict] = {}
    for record in records:
        for item in record.items:
            key = item.food.strip().lower()
            agg = aggregate.setdefault(
                key,
                {
                    "food": item.food,
                    "category": item.category,
                    "total_weight_oz": 0.0,
                    "total_cost_usd": 0.0,
                    "occurrences": 0,
                    "avoidable_weight_oz": 0.0,
                    "unavoidable_weight_oz": 0.0,
                    "max_portion_pct": 0.0,
                },
            )
            agg["total_weight_oz"] += item.estimated_weight_oz
            agg["total_cost_usd"] += item.estimated_cost_usd
            agg["occurrences"] += 1
            if item.avoidable:
                agg["avoidable_weight_oz"] += item.estimated_weight_oz
            else:
                agg["unavoidable_weight_oz"] += item.estimated_weight_oz
            if item.estimated_portion_wasted_pct > agg["max_portion_pct"]:
                agg["max_portion_pct"] = item.estimated_portion_wasted_pct

    ranked = sorted(aggregate.values(), key=lambda a: a["total_weight_oz"], reverse=True)

    parts.append("\n=== DETECTED WASTE (aggregated across all scans, ranked by total weight) ===")
    parts.append("These are the ONLY foods you should recommend action on:")
    if not ranked:
        parts.append("  (no items detected)")
    for a in ranked:
        parts.append(
            f"  - {a['food']} [{a['category']}]: {a['total_weight_oz']:.1f} oz total, "
            f"${a['total_cost_usd']:.2f} total, seen in {a['occurrences']} scan(s), "
            f"peak {a['max_portion_pct']:.0f}% of serving wasted, "
            f"avoidable {a['avoidable_weight_oz']:.1f} oz / unavoidable {a['unavoidable_weight_oz']:.1f} oz"
        )

    parts.append("\n=== PER-SCAN DETAIL ===")
    for i, record in enumerate(records, 1):
        parts.append(f"\n--- Scan {i} ({record.created_at.strftime('%Y-%m-%d %H:%M')}) ---")
        parts.append(f"Waste severity: {record.summary.waste_severity}")
        parts.append(f"Total avoidable waste: {record.summary.avoidable_weight_oz:.1f} oz (${record.summary.avoidable_cost_usd:.2f})")
        parts.append(f"Total unavoidable waste: {record.summary.unavoidable_weight_oz:.1f} oz")
        parts.append("Items detected in this scan:")
        for item in record.items:
            tag = "AVOIDABLE" if item.avoidable else "unavoidable"
            parts.append(
                f"  - {item.food} [{item.category}]: {item.estimated_weight_oz:.1f} oz, "
                f"{item.estimated_portion_wasted_pct:.0f}% of serving wasted, "
                f"${item.estimated_cost_usd:.2f} [{tag}]"
            )

    return "\n".join(parts)


def generate_recommendations(records: list[AnalysisRecord]) -> RecommendationsResult:
    backend = settings.recommendations_backend
    errors: list[str] = []
    generators = []

    if backend == "jac":
        generators = [_generate_with_jac]
    elif backend == "python":
        generators = [_generate_with_python_llm]
    else:
        generators = [_generate_with_python_llm, _generate_with_jac]

    for generator in generators:
        try:
            return generator(records)
        except (RuntimeError, ValueError) as exc:
            generator_name = getattr(generator, "__name__", generator.__class__.__name__)
            errors.append(f"{generator_name}: {exc}")

    raise RuntimeError("Recommendation generation failed: " + " | ".join(errors))


def _generate_with_jac(records: list[AnalysisRecord]) -> RecommendationsResult:
    return jac_recommender_adapter.generate_recommendations(build_recommendation_prompt(records))


def _generate_with_python_llm(records: list[AnalysisRecord]) -> RecommendationsResult:
    user_message = build_recommendation_prompt(records)
    raw = llm_provider.complete_text(
        system_prompt=SYSTEM_PROMPT,
        user_message=user_message,
        max_tokens=RECOMMENDATION_MAX_TOKENS,
    ).strip()
    if raw.startswith("```"):
        lines = raw.splitlines()
        raw = "\n".join(lines[1:-1] if lines[-1].strip() == "```" else lines[1:])

    try:
        data = json.loads(raw)
    except json.JSONDecodeError as e:
        raise ValueError(f"LLM returned invalid JSON: {e}\n\nRaw:\n{raw}") from e

    return RecommendationsResult(
        generated_at=datetime.now(timezone.utc),
        menu_delta=data.get("menu_delta", []),
        insights=[RecommendationInsight(**ins) for ins in data.get("insights", [])],
        summary_text=data.get("summary_text", ""),
    )
