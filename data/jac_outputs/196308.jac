"""Checks if value belongs to the interval [inf - dist, sup + dist]."""
def interval_condition(value: float, inf: float, sup: float, dist: float) -> bool {
    return inf - dist < value < sup + dist;
}