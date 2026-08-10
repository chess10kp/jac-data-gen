"""Exponential mapping."""
def exp_map(val: float, lo: float, hi: float) -> float {
    return pow(hi / lo, val) * lo;
}