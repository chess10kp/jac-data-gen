import json
from pathlib import Path

from config import settings
from models.schemas import WasteItem, WasteSummary
from services import jac_adapter, llm_provider

BASE_SYSTEM_PROMPT = """You are a food waste analysis system for university dining halls.
Given an image of a trash bin or food waste, analyze the contents and respond ONLY with valid JSON (no markdown, no backticks) in this exact format:

{
  "items": [
    {
      "food": "name of food item",
      "category": "protein" | "grain" | "dairy" | "fruit" | "vegetable" | "beverage" | "dessert" | "bakery" | "snack" | "sauce" | "soup" | "mixed" | "other",
      "estimated_weight_oz": number,
      "estimated_portion_wasted_pct": number (0-100),
      "estimated_cost_usd": number,
      "avoidable": boolean
    }
  ],
  "summary": {
    "total_items": number,
    "total_estimated_weight_oz": number,
    "total_estimated_cost_usd": number,
    "most_wasted_category": "string",
    "waste_severity": "low" | "medium" | "high" | "critical",
    "avoidable_weight_oz": number,
    "unavoidable_weight_oz": number,
    "avoidable_cost_usd": number,
    "unavoidable_cost_usd": number
  },
  "notes": "any relevant observations"
}

AVOIDABLE vs UNAVOIDABLE:
- avoidable: true — edible food that was served but not eaten (uneaten rice, protein, vegetables, bread, etc.)
- avoidable: false — inedible byproduct (bones, shells, peels, cores, coffee grounds, napkins, plastic utensils, liquid)

IMPORTANT RULES FOR estimated_portion_wasted_pct:
- This field should represent each item's share of the total visible waste in the image.
- Across all returned items, estimated_portion_wasted_pct should add up to about 100.
- Example: if rice looks like half the bin and broccoli looks like one quarter, use about 50 and 25.
- Do NOT set every item to 100 unless there is truly only one item in the image.

MENU MATCHING RULES:
- Use an exact menu item name when the waste clearly matches something from today's menu.
- If the waste does not fit a menu item, name the actual observed item instead of forcing a menu match.
- For scraps, peels, bones, shells, and mixed leftovers, prefer the observed waste description over a menu item.

Be specific about food items. Estimate weights and costs based on typical US dining hall pricing.
If the image is unclear, do your best and note uncertainty in the notes field."""


def load_constant_items() -> list[str]:
    path = settings.constant_items_file
    if path.exists():
        items = [line.strip() for line in path.read_text().splitlines() if line.strip()]
        if items:
            return _dedupe_preserve_order(items)
    return _dedupe_preserve_order(settings.default_constant_items)


def _build_system_prompt(menu_items: list[str], constant_items: list[str]) -> str:
    sections = [BASE_SYSTEM_PROMPT]

    if menu_items:
        menu_list = "\n".join(f"  - {item}" for item in menu_items)
        sections.append(
            f"""

IMPORTANT: Prioritize classifying waste using items from today's menu. If something matches a menu item, use that name exactly.

Today's menu:
{menu_list}"""
        )

    if constant_items:
        constant_list = "\n".join(f"  - {item}" for item in constant_items)
        sections.append(
            f"""

Dining hall constant items that may appear regularly even if they are not on the menu:
{constant_list}

Use these names when they better fit the image than a menu item."""
        )

    return "".join(sections)


def _parse_response(raw: str) -> dict:
    raw = raw.strip()
    if raw.startswith("```"):
        lines = raw.splitlines()
        raw = "\n".join(lines[1:-1] if lines[-1].strip() == "```" else lines[1:])
    return json.loads(raw)


def analyze_waste(
    image_path: Path,
    menu_items: list[str],
    constant_items: list[str] | None = None,
) -> tuple[list[WasteItem], WasteSummary, str]:
    normalized_menu = _dedupe_preserve_order(menu_items)
    normalized_constant_items = _dedupe_preserve_order(constant_items or [])

    backend = settings.analysis_backend
    errors: list[str] = []
    analyzers = []

    if backend == "jac":
        analyzers = [_analyze_with_jac]
    elif backend == "python":
        analyzers = [_analyze_with_python_llm]
    else:
        analyzers = [_analyze_with_jac, _analyze_with_python_llm]

    for analyzer in analyzers:
        try:
            return analyzer(image_path, normalized_menu, normalized_constant_items)
        except (RuntimeError, ValueError) as exc:
            analyzer_name = getattr(analyzer, "__name__", analyzer.__class__.__name__)
            errors.append(f"{analyzer_name}: {exc}")

    raise RuntimeError("Vision analysis failed: " + " | ".join(errors))


def _analyze_with_jac(
    image_path: Path,
    menu_items: list[str],
    constant_items: list[str],
) -> tuple[list[WasteItem], WasteSummary, str]:
    return jac_adapter.analyze_waste(image_path, menu_items, constant_items)


def _analyze_with_python_llm(
    image_path: Path,
    menu_items: list[str],
    constant_items: list[str],
) -> tuple[list[WasteItem], WasteSummary, str]:
    system_prompt = _build_system_prompt(menu_items, constant_items)
    raw = llm_provider.complete_image(
        system_prompt=system_prompt,
        image_path=image_path,
        user_text="Analyze the food waste in this image.",
        max_tokens=1500,
    )

    try:
        data = _parse_response(raw)
    except json.JSONDecodeError as e:
        raise ValueError(f"LLM returned invalid JSON: {e}\n\nRaw response:\n{raw}") from e

    items = [WasteItem(**item) for item in data["items"]]
    items = _normalize_item_percentages(items)
    summary = _rebuild_summary(items, data["summary"])
    notes = data.get("notes", "")
    return items, summary, notes


def _dedupe_preserve_order(values: list[str]) -> list[str]:
    items: list[str] = []
    seen: set[str] = set()

    for value in values:
        normalized = value.strip()
        if not normalized:
            continue
        key = normalized.lower()
        if key in seen:
            continue
        seen.add(key)
        items.append(normalized)

    return items


def _normalize_item_percentages(items: list[WasteItem]) -> list[WasteItem]:
    if not items:
        return items

    total_weight = sum(max(item.estimated_weight_oz, 0.0) for item in items)
    if total_weight > 0:
        normalized = []
        running_total = 0.0
        for item in items:
            pct = round((max(item.estimated_weight_oz, 0.0) / total_weight) * 100, 1)
            running_total += pct
            normalized.append(item.model_copy(update={"estimated_portion_wasted_pct": pct}))

        drift = round(100.0 - running_total, 1)
        if normalized and abs(drift) > 0:
            last = normalized[-1]
            normalized[-1] = last.model_copy(
                update={
                    "estimated_portion_wasted_pct": max(
                        0.0,
                        round(last.estimated_portion_wasted_pct + drift, 1),
                    )
                }
            )
        return normalized

    total_pct = sum(max(item.estimated_portion_wasted_pct, 0.0) for item in items)
    if total_pct <= 0:
        equal_pct = round(100.0 / len(items), 1)
        normalized = [
            item.model_copy(update={"estimated_portion_wasted_pct": equal_pct})
            for item in items
        ]
        drift = round(100.0 - sum(item.estimated_portion_wasted_pct for item in normalized), 1)
        last = normalized[-1]
        normalized[-1] = last.model_copy(
            update={"estimated_portion_wasted_pct": max(0.0, round(last.estimated_portion_wasted_pct + drift, 1))}
        )
        return normalized

    normalized = []
    running_total = 0.0
    for item in items:
        pct = round((max(item.estimated_portion_wasted_pct, 0.0) / total_pct) * 100, 1)
        running_total += pct
        normalized.append(item.model_copy(update={"estimated_portion_wasted_pct": pct}))

    drift = round(100.0 - running_total, 1)
    last = normalized[-1]
    normalized[-1] = last.model_copy(
        update={"estimated_portion_wasted_pct": max(0.0, round(last.estimated_portion_wasted_pct + drift, 1))}
    )
    return normalized


def _rebuild_summary(items: list[WasteItem], raw_summary: dict) -> WasteSummary:
    total_weight = round(sum(item.estimated_weight_oz for item in items), 2)
    total_cost = round(sum(item.estimated_cost_usd for item in items), 2)
    avoidable_weight = round(sum(item.estimated_weight_oz for item in items if item.avoidable), 2)
    unavoidable_weight = round(sum(item.estimated_weight_oz for item in items if not item.avoidable), 2)
    avoidable_cost = round(sum(item.estimated_cost_usd for item in items if item.avoidable), 2)
    unavoidable_cost = round(sum(item.estimated_cost_usd for item in items if not item.avoidable), 2)

    category_totals: dict[str, float] = {}
    for item in items:
        category_totals[item.category] = category_totals.get(item.category, 0.0) + item.estimated_weight_oz
    most_wasted_category = max(category_totals, key=category_totals.get) if category_totals else "other"

    waste_severity = raw_summary.get("waste_severity", "low")
    if waste_severity not in {"low", "medium", "high", "critical"}:
        waste_severity = "low"

    return WasteSummary(
        total_items=len(items),
        total_estimated_weight_oz=total_weight,
        total_estimated_cost_usd=total_cost,
        most_wasted_category=most_wasted_category,
        waste_severity=waste_severity,
        avoidable_weight_oz=avoidable_weight,
        unavoidable_weight_oz=unavoidable_weight,
        avoidable_cost_usd=avoidable_cost,
        unavoidable_cost_usd=unavoidable_cost,
    )
