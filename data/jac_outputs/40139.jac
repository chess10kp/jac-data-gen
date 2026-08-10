"""Calculate Phi-squared from chi-squared and population size."""
def phi_square_calc(chi_square: float, POP: int) -> float | str {
    try {
        return chi_square / POP;
    } except Exception {
        return "None";
    }
}