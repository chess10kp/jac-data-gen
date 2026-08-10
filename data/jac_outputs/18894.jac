"""

Find how many years away was the closest leap year to a specific year

"""
def closeyear(year: int) -> int {
    return int(year % 4);
}