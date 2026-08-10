"""
    Unified rounding in all python versions.

    Parameters:
    ----------
    number : float
        Input number.

    Returns:
    -------
    int
        Output rounded number.
    """
def round_float_math(number: float) -> int {
    if (abs((round(number) - number)) == 0.5) {
        return int((2.0 * round((0.5 * number))));
    } else {
        return int(round(number));
    }
}