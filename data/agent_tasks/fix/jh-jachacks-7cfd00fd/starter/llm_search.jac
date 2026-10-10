import from byllm.llm { Model }

glob llm = Model(model_name="claude-sonnet-4-6");

# ── LLM Search Function ───────────────────────────────────────────────────────

"""
Search the internet for real grocery stores, supermarkets, health food shops, farmers
markets, and specialty food retailers near `location` within `radius_miles` miles.
For each store list specific food items that are safe and relevant for the user.

HARD CONSTRAINTS — never violate under any circumstances:
  - `allergies`: Never include any food containing these allergens.
  - `conditions`: Never include foods incompatible with these medical conditions
    (e.g. diabetes -> avoid high-sugar items; celiac -> no gluten).
  - `restrictions`: Never violate these dietary lifestyles (vegan, halal, kosher, etc.).

SOFT CONSTRAINTS — stay within +/-`macro_flex_pct`% of each target:
  - calories, protein_g, carbs_g, fat_g per meal
  - budget per meal in USD

Return a Python dict with exactly this structure:
{
  "stores": [
    {
      "name": str,
      "address": str,
      "distance_miles": float,
      "type": str,
      "hours": str,
      "items": [
        {
          "name": str,
          "category": str,
          "estimated_price": float,
          "unit": str,
          "macros_per_100g": {"calories": int, "protein_g": float, "carbs_g": float, "fat_g": float},
          "notes": str
        }
      ]
    }
  ],
  "recipes": [
    {
      "name": str,
      "description": str,
      "prep_time_mins": int,
      "cook_time_mins": int,
      "servings": int,
      "estimated_cost": float,
      "macros_per_serving": {"calories": int, "protein_g": float, "carbs_g": float, "fat_g": float},
      "macro_deviation_pct": float,
      "budget_deviation_pct": float,
      "ingredients": [{"item": str, "quantity": str, "store": str, "estimated_price": float}],
      "instructions": [str],
      "tags": [str]
    }
  ],
  "summary": str
}
Generate 3 to 5 practical recipes using items from the found stores. Include only items
that satisfy ALL hard constraints. Ensure each recipe respects hard constraints fully
and stays within the soft constraint tolerance. Return valid Python dict syntax only.
"""
def find_food_and_recipes(
    location: str,
    radius_miles: float,
    allergies: list[str],
    budget: float,
    calories: int,
    protein_g: int,
    carbs_g: int,
    fat_g: int,
    macro_flex_pct: int,
    conditions: list[str],
    restrictions: list[str]
) -> dict by llm();
