glob MAX_HHMMSS_SECONDS = (99 * 3600) + (59 * 60) + 59;

"""
    Convert seconds into a time-string with the format HH:MM:SS.  Seconds should
    be an integer or float (rounded to nearest second and then cast to int).
    """
def _seconds_to_time(seconds: int | float) -> str {
    try {
        if not (`type(seconds) is int) {
            seconds = int(round(seconds, 0));
        }
    } except TypeError {
        err = "seconds must be able to be converted to an integer\n";
        raise ValueError(err);
    }
    if seconds > MAX_HHMMSS_SECONDS {
        err = "times longer than {} (99:59:59) cannot be represented in HH:MM:SS.\n".format(
            MAX_HHMMSS_SECONDS
        );
        raise ValueError(err);
    }
    hours = seconds // 3600;
    leftover = seconds - (hours * 3600);
    minutes = leftover // 60;
    seconds = leftover - (minutes * 60);
    try {
        assert seconds >= 0 and seconds < 60;
        assert minutes >= 0 and minutes < 60;
        assert hours >= 0 and hours < 100;
    } except AssertionError {
        err = "time could not be converted to HH:MM:SS format.\n";
        err += "gave: {} hours, {} minutes, {} seconds\n".format(
            hours, minutes, seconds
        );
        raise RuntimeError(err);
    }
    return "{:02}:{:02}:{:02}".format(hours, minutes, seconds);
}