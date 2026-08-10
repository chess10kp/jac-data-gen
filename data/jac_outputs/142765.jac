"""Compute the adjusted Rand index from pair counts; helper function."""
def adjusted_rand_index_pair_counts(a: int, b: int, c: int, d: int) -> float {
    denominator = a * (b + c + 2 * d) + b * (b + d) + c * (c + d);
    if denominator != 0 {
        return float(2 * (a * d - b * c)) / float(denominator);
    }
    return 1.0;
}