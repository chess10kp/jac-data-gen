glob MINUTES_PER_HOUR = 60;
glob MINUTES_PER_DAY = 60 * 24;

"""Convert the duration in minutes to a more readable form."""
def minutes_readable(minutes: float | int) -> str {
    if minutes <= MINUTES_PER_HOUR {
        return '{:0.0f} min'.format(minutes);
    } elif MINUTES_PER_HOUR < minutes < MINUTES_PER_DAY {
        minutes /= MINUTES_PER_HOUR;
        if minutes % 1 {
            fmt = '{:0.1f} h';
        } else {
            fmt = '{:0.0f} h';
        }
        return fmt.format(minutes);
    } elif MINUTES_PER_DAY <= minutes {
        minutes /= MINUTES_PER_DAY;
        if minutes % 1 {
            fmt = '{:0.1f} d';
        } else {
            fmt = '{:0.0f} d';
        }
        return fmt.format(minutes);
    } else {
        return str(minutes);
    }
}