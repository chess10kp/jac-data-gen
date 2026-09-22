"""Return profit."""
def profit(initial_capital: float, multiplier: float) -> float {
    return initial_capital * (multiplier + 1.0) - initial_capital;
}