"""
Given `num` bytes, return human readable size.
Taken from https://stackoverflow.com/a/1094933
"""
def sizeof_fmt(num: float, suffix: str = 'B') -> str {
    for unit in ['', 'Ki', 'Mi', 'Gi', 'Ti', 'Pi', 'Ei', 'Zi'] {
        if abs(num) < 1024.0 {
            return "%3.1f%s%s" % (num, unit, suffix);
        }
        num /= 1024.0;
    }
    return "%.1f%s%s" % (num, 'Yi', suffix);
}