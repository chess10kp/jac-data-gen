"""
    Bounded exponential function
    Computes an exponential function where when
     x is 0, the output is bounds[0], and when
     x is 1, the output is bounds[1]. The relative
     probability of outputting bounds[0[ over bounds[1]
     is base.
    Useful for randomly sampling over large ranges of
     values with an exponential resolution.
    RH 2021

    Args:
        x (float or np.ndarray):
            Float or 1-D array of the x-axis
        bounds (list):
            List of two floats, the lower and upper
             bounds
        base (float):
            The relative probability of outputting
             bounds[0] over bounds[1]

    Returns:
        output (float or np.ndarray):
            The bounded exponential output
    """
def bounded_exponential(x: Any, bounds: Any = [(1 / 10), 10], base: Any = 2) -> object {
    range_additive = bounds[1] - bounds[0];
    return (((((base ** x) - 1) / (base - 1)) * range_additive) + bounds[0]);
}