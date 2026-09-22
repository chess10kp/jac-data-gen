"""Derivative evaluated as 1 - x² (same logic as the sigmoid derivative form)."""
def tanh_derivative(x: float | int) -> float {
    return 1 - x ** 2;
}