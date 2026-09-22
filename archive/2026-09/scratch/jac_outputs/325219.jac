"""Split year_month_day by '-' and return year and month as ints."""
def year_month_sorter(x: str) -> list[int] {
    (y, m) = x.split('-');
    [int(y), int(m)]
}