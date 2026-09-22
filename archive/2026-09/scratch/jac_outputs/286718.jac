"""Approximate fx'(x) via the five-point finite-difference stencil."""
def FivePointsDiff(fx: Callable[[float], float], x: float, h: float = 0.001) -> float {
    return (
        -fx(x + 2 * h) + 8 * fx(x + h) - 8 * fx(x - h) + fx(x - 2 * h)
    ) / (12.0 * h);
}