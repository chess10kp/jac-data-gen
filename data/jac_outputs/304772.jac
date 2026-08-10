"""Return True if any needle is a substring of haystack."""
def contains_any(haystack: str, needles: list[str]) -> bool {
    return any(n in haystack for n in needles);
}