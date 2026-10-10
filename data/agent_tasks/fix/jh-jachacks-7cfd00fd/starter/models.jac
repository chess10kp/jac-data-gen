# ── Data Nodes ────────────────────────────────────────────────────────────────

node UserPreferences {
    has location: str,
        radius_miles: float,
        allergies: list[str],
        budget: float,
        calories: int,
        protein_g: int,
        carbs_g: int,
        fat_g: int,
        macro_flex_pct: int,
        conditions: list[str],
        restrictions: list[str],
        created_at: str = "";
}

node SearchResult {
    has stores: list[dict] = [],
        recipes: list[dict] = [],
        summary: str = "",
        created_at: str = "";
}
