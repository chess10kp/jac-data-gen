"""Return name of weekday.

        >>> weekday_name(1)
        'Sunday'

        >>> weekday_name(7)
        'Saturday'

    For days not between 1 and 7, return None

        >>> weekday_name(9)
        >>> weekday_name(0)
    """
def weekday_name(day_of_week: Any) -> object {
    DAYS = [
        "Sunday",
        "Monday",
        "Tuesday",
        "Wednesday",
        "Thursday",
        "Friday",
        "Saturday"
    ];
    if ((day_of_week < 1) or (day_of_week > 7)) {
        return None;
    }
    return DAYS[(day_of_week - 1)];
}