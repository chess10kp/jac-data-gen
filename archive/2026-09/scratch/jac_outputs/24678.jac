"""Add one month to the received year/month."""
def _increment_year_month(year: int, month: int) -> tuple[int, int] {
    month += 1;
    if month == 13 {
        year += 1;
        month = 1;
    }
    return (year, month);
}