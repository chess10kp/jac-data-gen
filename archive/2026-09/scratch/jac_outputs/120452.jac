"""Convert bytes length to a human-readable version."""
def human_size(num: int | float, suffix: str = 'B') -> str {
    for unit in ['', 'Ki', 'Mi', 'Gi', 'Ti', 'Pi', 'Ei', 'Zi'] {
        if abs(num) < 1024.0 {
            return "{0:3.1f}{1!s}{2!s}".format(num, unit, suffix);
        }
        num /= 1024.0;
    }
    return "{0:.1f}{1!s}{2!s}".format(num, 'Yi', suffix);
}