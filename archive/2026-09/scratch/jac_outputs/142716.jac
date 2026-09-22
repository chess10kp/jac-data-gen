"""Integrate fx from x_min to x_max using the trapezoidal rule."""
def trapezoidal(
    f: Callable[[float], float],
    x_min: float,
    x_max: float,
    n: int = 1000
) -> float {
    h = (x_max - x_min) / n;
    jum = 0.5 * f(x_min);
    for i in range(1, n) {
        xi = x_min + h * i;
        jum = jum + f(xi);
    }
    jum = jum + 0.5 * f(x_max);
    return jum * h;
}