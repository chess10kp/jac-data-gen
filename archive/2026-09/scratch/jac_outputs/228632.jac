"""Calculate the number of characters that differ between two strings of identical length.

    Returns 1 if lengths do not match.
    """
def string_distance(s1: str, s2: str) -> int {
    if len(s1) != len(s2) {
        return 1;
    }
    return sum(1 for (c1, c2) in zip(s1, s2) if c1 != c2);
}