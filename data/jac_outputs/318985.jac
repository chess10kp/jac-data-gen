"""Alpha function: determines extent to which node matrix is altered over time. Exponential function with half life of 160 iterations."""
def alpha_fixed(s: int) -> float {
    return 0.5 * (2 ** (-s / 240));
}