"""Check if a given year `year` is a leap year."""
def is_leap_year(year: int) -> bool {
    return year % 4 == 0 and (year % 100 != 0 or year % 400 == 0);
}