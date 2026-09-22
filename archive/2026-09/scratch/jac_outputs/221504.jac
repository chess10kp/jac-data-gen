"""Convert a pattern of '0', '1', and '2' to a similarity rating."""
def pattern_to_similarity(pattern: str) -> int {
    int(pattern[::-1], 3)
}