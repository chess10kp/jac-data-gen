"""Returns the year, month, day of the next day. Simple version: assume every month has 30 days."""
def nextDay(year: int, month: int, day: int) -> tuple[int, int, int] {
    if day >= 30 {
        day = 1;
        month += 1;
    } else {
        day += 1;
    }
    if month > 12 {
        year += 1;
        month = 1;
    }
    return (year, month, day);
}