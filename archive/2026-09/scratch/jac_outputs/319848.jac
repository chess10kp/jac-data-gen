"""
    Find the root of f(x) = 0 using the Newton-Raphson method recursively.

    Parameters
    ----------
        f       - function
        f_prime - derivative of f
        x0      - starting value
        tol     - tolerance

    Returns
    -------
    root of f(x)
    """
def newton(
    f: Callable[[float], float],
    f_prime: Callable[[float], float],
    x0: float,
    tol: float
) -> float {
    if abs(f(x0)) < tol {
        return x0;
    }
    x1 = x0 - f(x0) / f_prime(x0);
    print("x0 = ", x0, "f(x0) = ", f(x0), "f'(x0) =", f_prime(x0), "x1 = ", x1);
    return newton(f, f_prime, x1, tol);
}