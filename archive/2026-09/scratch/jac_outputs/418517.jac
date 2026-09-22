"""Calculate mean of a sequence; return empty if the sequence is empty."""
def mean(values: Iterable[float], empty: float = 0) -> float {
    (n, mean_val) = (0, 0.0);
    for value in values {
        n += 1;
        mean_val += (value - mean_val) / n;
    }
    return mean_val if n > 0 else empty;
}