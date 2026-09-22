"""Convert a number of bytes to a human-readable format."""
def bytesfilter(num: float, suffix: str = "B") -> str {
    for unit in ["", "Ki", "Mi", "Gi", "Ti", "Pi", "Ei", "Zi"] {
        if abs(num) < 1024.0 {
            return "%3.0f %s%s" % (num, unit, suffix);
        }
        num /= 1024.0;
    }
    return "%.0f %s%s" % (num, "Yi", suffix);
}