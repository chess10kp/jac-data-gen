"""Calculates chao1 variance in absence of doubletons.

From EstimateS manual, equation 7.

chao1 is the estimate of the mean of Chao1 from the same dataset.
"""
def chao1_var_no_doubletons(singles: int | float, chao1: float) -> float {
    s = float(singles);
    return (s * (s - 1)) / 2 + (s * ((2 * s) - 1) ** 2) / 4 - (s ** 4) / (4 * chao1);
}