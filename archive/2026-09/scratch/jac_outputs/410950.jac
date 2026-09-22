"""Hill equation."""
def hill_equation(val: float, diss_cf: float, hill_cf: float) -> float {
    if val == 0 {
        return 0;
    }
    return 1 / (1 + (diss_cf / val) ** hill_cf);
}