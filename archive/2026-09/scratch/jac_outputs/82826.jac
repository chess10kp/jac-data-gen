"""Computes the Inverse-Quadratic Radial Basis Function between two points with distance `r`."""
def inverse_quadratic_rbf(r: float, kappa: float) -> float {
    1.0 / (1.0 + (r * kappa) ** 2.0)
}