"""Calculates chao1, uncorrected.

    From EstimateS manual, equation 5.
    """
def chao1_var_uncorrected(singles: int | float, doubles: int | float) -> float {
    r = float(singles) / doubles;
    return doubles * (0.5 * r ** 2 + r ** 3 + 0.24 * r ** 4);
}