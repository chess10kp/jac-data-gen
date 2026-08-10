"""Convert a period (in AAAAMM form) to a date (in MM/AAAA form)."""
def period_to_date(period: str) -> str {
    month = period[4:6];
    year = period[0:4];
    return month + '/' + year;
}