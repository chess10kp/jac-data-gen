import from calendar { monthrange }

"""Returns the number of days in the month of a specific year."""
def get_days_in_month(year: int, month: int) -> int {
    return monthrange(year, month)[1];
}