glob SECONDS_PER_DAY = 86400;
glob SECONDS_PER_HOUR = 3600;
glob SECONDS_PER_MINUTE = 60;

"""Converts a number of seconds to a human-readable time in seconds, minutes, and hours."""
def readable_time(seconds: int | float) -> str {
    parts: list[str] = [];
    if seconds >= SECONDS_PER_DAY {
        days = seconds // SECONDS_PER_DAY;
        parts.append(f"{int(days)} {'day' if days == 1 else 'days'}");
    }
    if seconds >= SECONDS_PER_HOUR {
        hours = (seconds // SECONDS_PER_HOUR) % 24;
        parts.append(f"{int(hours)} {'hour' if hours == 1 else 'hours'}");
    }
    if seconds >= SECONDS_PER_MINUTE {
        minutes = (seconds // SECONDS_PER_MINUTE) % 60;
        parts.append(f"{int(minutes)} {'minute' if minutes == 1 else 'minutes'}");
    }
    seconds = round(seconds % SECONDS_PER_MINUTE, 2);
    parts.append(f"{seconds} {'second' if seconds == 1 else 'seconds'}");
    return ", ".join(parts);
}