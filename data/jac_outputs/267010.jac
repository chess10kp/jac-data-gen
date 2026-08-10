"""Return the sample arithmetic mean of data."""
def mean(data: list[float]) -> float {
    n = len(data);
    if n < 1 {
        raise ValueError('mean requires at least one data point');
    }
    return sum(data) / n;
}