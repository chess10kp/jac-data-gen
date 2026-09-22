"""Given a year, return the century it is in."""
def century(year: int) -> int {
    if year % 100 == 0 {
        return year // 100;
    }
    year // 100 + 1
}