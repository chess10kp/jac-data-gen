"""Integral of polynomial order 3 where f(x) = a + b * x + c * x**2 + d * x**3."""
def polynomial_3_integral(x0: int | float, x1: int | float, a: int | float, b: int | float, c: int | float, d: int | float) -> float {
    return (
        a * (x1 - x0)
        + b * (x1 ** 2 - x0 ** 2) / 2.0
        + c * (x1 ** 3 - x0 ** 3) / 3.0
        + d * (x1 ** 4 - x0 ** 4) / 4.0
    );
}