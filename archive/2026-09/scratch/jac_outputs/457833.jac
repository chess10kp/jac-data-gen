"""Returns the Hamming Distance of Two Equal Strings."""
def hamming_distance(lhs: str, rhs: str) -> int {
    return sum(x != y for (x, y) in zip(lhs, rhs));
}