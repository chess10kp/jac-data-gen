"""Format bytes as human readable size."""
def sizeformat(num: int | float, suffix: str = 'B') -> str {
    for unit in ['', 'Ki', 'Mi', 'Gi', 'Ti', 'Pi', 'Ei', 'Zi'] {
        if abs(num) < 1024.0 {
            return "%3.1f %s%s" % (num, unit, suffix);
        }
        num /= 1024.0;
    }
    return "%.1f %s%s" % (num, 'Yi', suffix);
}