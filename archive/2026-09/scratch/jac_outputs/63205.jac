"""Heuristic for default boxplot grouping."""
def default_grouping(datasets: int, date_field: str | None = None) -> str {
    if datasets > 20 and date_field {
        return "year";
    } elif datasets > 10 or not date_field {
        return "series";
    } else {
        return "series-year";
    }
}