"""Extract year and day-of-year from an integer formatted as YYYYDDD."""
def get_year_and_day_of_year(year_and_day_of_year: int) -> tuple[int | None, int | None] {
    year = None;
    day_of_year = None;
    year_and_day_of_year_str = str(year_and_day_of_year);
    if len(year_and_day_of_year_str) >= 5 {
        year = int(year_and_day_of_year_str[:4]);
        day_of_year = int(year_and_day_of_year_str[4:]);
    }
    return (year, day_of_year);
}