"""Return the number of weeks and days in the given number of days."""
def readable_timedelta(days: int) -> str {
    number_of_weeks = days // 7;
    number_of_days = days % 7;
    return '{} week(s) and {} day(s)'.format(number_of_weeks, number_of_days);
}