import from datetime { datetime }

# ── Backend Public API ────────────────────────────────────────────────────────
# Depends on: models.jac (UserPreferences, SearchResult)
#             llm_search.jac (find_food_and_recipes)

def:pub save_and_search(
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
) -> dict {
    prefs = UserPreferences(
        location=location,
        radius_miles=radius_miles,
        allergies=allergies,
        budget=budget,
        calories=calories,
        protein_g=protein_g,
        carbs_g=carbs_g,
        fat_g=fat_g,
        macro_flex_pct=macro_flex_pct,
        conditions=conditions,
        restrictions=restrictions,
        created_at=str(datetime.now())
    );
    root() ++> prefs;

    data = find_food_and_recipes(
        location=location,
        radius_miles=radius_miles,
        allergies=allergies,
        budget=budget,
        calories=calories,
        protein_g=protein_g,
        carbs_g=carbs_g,
        fat_g=fat_g,
        macro_flex_pct=macro_flex_pct,
        conditions=conditions,
        restrictions=restrictions
    );

    sr = SearchResult(
        stores=data.get("stores", []),
        recipes=data.get("recipes", []),
        summary=data.get("summary", ""),
        created_at=str(datetime.now())
    );
    prefs ++> sr;
    return data;
}
