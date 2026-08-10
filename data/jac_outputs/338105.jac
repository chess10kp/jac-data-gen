"""A function for testing approximate equality of two numbers.
    Same as math.isclose in Python v3.5 (and newer)
    https://www.python.org/dev/peps/pep-0485
    """
def almost_equal(a: Any, b: Any, rel_tol: Any = 1e-09, abs_tol: Any = 0.0) -> object {
    return (abs((a - b)) <= max((rel_tol * max(abs(a), abs(b))), abs_tol));
}