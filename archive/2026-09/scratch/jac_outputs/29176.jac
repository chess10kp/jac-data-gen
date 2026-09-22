"""This method sets seconds in minutes, hours or days."""
def get_time_with_unit(time: int) -> str {
    sec_in_min = 60;
    sec_in_hour = 60 * 60;
    sec_in_day = 24 * 60 * 60;
    if time % sec_in_day == 0 {
        value = time / sec_in_day;
        unit = 'days';
    } elif time % sec_in_hour == 0 {
        value = time / sec_in_hour;
        unit = 'hours';
    } else {
        value = time / sec_in_min;
        unit = 'minutes';
    }
    return "%s %s" % (value, unit);
}