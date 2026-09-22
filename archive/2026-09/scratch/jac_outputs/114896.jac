"""Convert bytes int to int in aggregate units"""
def convert_bytes(num: int | float, suffix: str = 'B') -> str {
    for unit in ['', 'K', 'M', 'G', 'T', 'P', 'E', 'Z'] {
        if abs(num) < 1024.0 {
            return "%3.1f%s%s" % (num, unit, suffix);
        }
        num /= 1024.0;
    }
    return "%.1f%s%s" % (num, 'Yi', suffix);
}