"""Derivative of sigmoid function."""
def dsigmoid(x: float) -> float {
    return x * (1.0 - x);
}