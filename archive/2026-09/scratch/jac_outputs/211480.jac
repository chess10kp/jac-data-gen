"""Replaces the beginning of this string (until anchor) with base"""
def replaceTill(s: str, anchor: str, base: str) -> str {
    n = s.index(anchor);
    return base + s[n:];
}