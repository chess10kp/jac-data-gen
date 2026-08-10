"""Return a string describing the supplied number of seconds in human-readable time."""
def describe_interval(secs: int | float) -> str {
    if secs <= 0 {
        return 'no time at all';
    }
    hours = secs // 3600;
    minutes = (secs - hours * 3600) // 60;
    parts = [];
    if hours > 0 {
        if hours == 1 {
            parts.append('1 hour');
        } else {
            parts.append('%d hours' % hours);
        }
    }
    if minutes > 0 {
        if minutes == 1 {
            parts.append('1 minute');
        } else {
            parts.append('%d minutes' % minutes);
        }
    }
    if not (hours or minutes) {
        parts.append('less than a minute');
    }
    return ', '.join(parts);
}