"""ptp(m) returns the maximum - minimum along the first dimension of m."""
def ptp(m: list[float]) -> float {
    return max(m) - min(m);
}