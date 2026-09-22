"""Convert seconds to a formatted string

    Convert seconds: 3661
    To formatted: "   1:01:01"
    """
def format_seconds(seconds: int) -> str {
    hour_factor = 1;
    if seconds < 0 {
        hour_factor = -1;
        seconds = -seconds;
    }
    hours = seconds // 3600;
    minutes = (seconds % 3600) // 60;
    seconds = seconds % 60;
    return "{:4d}:{:02d}:{:02d}".format(hour_factor * hours, minutes, seconds);
}