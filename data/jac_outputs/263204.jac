"""Numerically approximate the second derivative of f at x0 using a centered difference."""
def differentiateTwice(f: Callable[[float], float], x0: float, h: float) -> float {
    (f(x0 + h) - 2 * f(x0) + f(x0 - h)) / (h * h)
}