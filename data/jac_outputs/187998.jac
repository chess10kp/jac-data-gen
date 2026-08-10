"""
    Creates a formatted string to express a length of time. Given a value in seconds, the value will
    be split into hours, minutes, and seconds based on how long that time period is.
    :param time_seconds: A value of time in seconds.
    :return: A formatted string expressing the time.
    """
def time_string(time_seconds: int | float) -> str {
    if time_seconds / 60 >= 1 {
        if time_seconds / 3600 >= 1 {
            time_minutes = time_seconds - (3600 * (time_seconds // 3600));
            num_hours = int(time_seconds // 3600);
            hours_string = "hour" if num_hours == 1 else "hours";
            num_minutes = int(time_minutes // 60);
            minutes_string = "minute" if num_minutes == 1 else "minutes";
            return "{} {}, {} {}, {:.3f} seconds".format(
                num_hours,
                hours_string,
                num_minutes,
                minutes_string,
                time_minutes % 60
            );
        } else {
            num_minutes = int(time_seconds // 60);
            minutes_string = "minute" if num_minutes == 1 else "minutes";
            return "{} {}, {:.3f} seconds".format(
                num_minutes, minutes_string, time_seconds % 60
            );
        }
    } else {
        return "{:.3f} seconds".format(time_seconds);
    }
}