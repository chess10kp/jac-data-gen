"""Number of occurrences of the exactly same characters in exactly same position."""
def commoncharacters(s1: str, s2: str) -> int {
    sum((c1 == c2) for (c1, c2) in zip(s1, s2))
}