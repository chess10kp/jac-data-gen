"""Returns the result of a regularised dirac function of the
    input value(s).
    """
def _cv_delta(x: float, eps: float = 1.0) -> float {
    return eps / (eps ** 2 + x ** 2);
}