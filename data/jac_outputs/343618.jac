"""
    Return a string of the number of weeks and days included in days.
    """
def readable_timedelta(days: int) -> str {
    weeks = days // 7;
    remainder = days % 7;
    return "{} week(s) and {} day(s)".format(weeks, remainder);
}