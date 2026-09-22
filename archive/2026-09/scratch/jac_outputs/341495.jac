"""return a copy of s. If the length of s > length, return part of it."""
def short_str(s: str, length: int = 35) -> str {
    return s[:(length - 3)] + '...' if len(s) > length else s;
}