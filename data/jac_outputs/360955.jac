"""Adds totals from item to totals."""
def add_to_tracking_totals(
    totals: dict[str, int | float | None], item: dict[str, int | float | None]
) -> dict[str, int | float | None] {
    for (key, value) in item.items() {
        if (
            type(value) is int and key not in ["GP", "W", "L", "TEAM_ID", "PLAYER_ID"]
        ) or key in [
            "MIN",
            "DIST_MILES",
            "DIST_MILES_OFF",
            "DIST_MILES_DEF",
            "TIME_OF_POSS",
        ] {
            if value is not None {
                totals[key] = totals.get(key, 0) + value;
            }
        }
    }
    return totals;
}