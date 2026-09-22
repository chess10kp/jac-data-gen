"""A highly accurate seven-point finite difference stencil for computing derivatives of a function."""
def f1d7p(f: Callable[[float], float], h: float) -> float {
    (fm3, fm2, fm1, f1, f2, f3) = [f(i * h) for i in [-3, -2, -1, 1, 2, 3]];
    return (f3 - 9 * f2 + 45 * f1 - 45 * fm1 + 9 * fm2 - fm3) / (60 * h);
}