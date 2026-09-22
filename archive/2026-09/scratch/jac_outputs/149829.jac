"""Build a year range from database bounds, optionally subset by first/last year."""
def build_years_array(
    db_years: list[int],
    first_year: int | None = None,
    last_year: int | None = None
) -> list[int] {
    fyear = max(first_year, db_years[0]) if first_year else db_years[0];
    lyear = min(last_year, db_years[1]) if last_year else db_years[1];
    return list(range(fyear, lyear + 1));
}