"""
    Return true solution for a test case where this is known.
    This function should satisfy u_{xx} + u_{yy} = 0.
    """
def utrue(x: float, y: float) -> float {
    return x ** 2 - y ** 2;
}