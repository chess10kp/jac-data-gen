"""Calculates the geometric mean rate of return given a list of returns."""
def meanreturn(rates: list[float]) -> float {
    prod = 1.0;
    for r in rates {
        prod = prod * (1 + r);
    }
    return (prod ** (1.0 / len(rates))) - 1;
}