"""Round to n significant digits."""
def _roundsf(x: int | float, n: int) -> float {
    return float('{:.{p}g}'.format(x, p=n));
}