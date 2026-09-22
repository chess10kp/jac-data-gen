"""Truncate a string."""
def truncate(base: str, length: int, ellipsis: str = "...") -> str {
    lenbase = len(base);
    if length >= lenbase {
        return base;
    }
    return base[:(length - len(ellipsis))] + ellipsis;
}