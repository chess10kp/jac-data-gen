"""Extracts contents between 2 bookend strings, non-inclusive."""
def between(s: str, start: str, end: str) -> str {
    s.split(start)[1].split(end)[0].strip()
}