"""ODE for the logistic equation."""
def logistic_equation(_: float, x: float, k: float, g: float) -> float {
    return k * x * (g - x);
}