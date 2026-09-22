"""Return the summation from i1 to i2 of n^2."""
def summ_nsqr(i1: int, i2: int) -> float {
    return (i2 * (i2 + 1) * (2 * i2 + 1)) / 6 - ((i1 - 1) * i1 * (2 * (i1 - 1) + 1)) / 6;
}