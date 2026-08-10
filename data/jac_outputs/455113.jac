"""Returns a simplified string representation of the given timedelta."""
def format_timedelta(
    days: int = 0, hours: int = 0, minutes: int = 0, seconds: int = 0
) -> str {
    s = '' if days == 0 else f'{days:d}d';
    if hours > 0 {
        if len(s) > 0 {
            s += ' ';
        }
        s += f'{hours:d}h';
    }
    if minutes > 0 {
        if len(s) > 0 {
            s += ' ';
        }
        s += f'{minutes:d}min';
    }
    if seconds > 0 or len(s) == 0 {
        if len(s) > 0 {
            s += ' ';
        }
        s += f'{seconds:d}sec';
    }
    return s;
}