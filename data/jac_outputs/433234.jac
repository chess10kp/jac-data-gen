"""Get the Cohen's-d value for a multiple comparison test."""
def cohens_d_multiple(xbar1: float, xbar2: float, ms_with: float) -> float {
    return (xbar1 - xbar2) / (ms_with ** 0.5);
}