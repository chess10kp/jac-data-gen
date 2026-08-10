"""Computes zscore with precomputed denominator."""
def zscore_den(observed: int | float, expected: int | float, N: int | float, denom: int | float) -> float {
    x = float(observed - expected) / float(N);
    return x / denom;
}