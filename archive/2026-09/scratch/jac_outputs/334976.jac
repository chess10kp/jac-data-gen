"""Check whether given year is a leap year."""
def leap_year(year: int) -> bool {
    year % 4 == 0 and year % 100 != 0 or year % 400 == 0
}