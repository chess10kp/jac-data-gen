"""
    Calculates an rgb color of a value depending of
    the minimum and maximum values.

    Parameters
    ----------
    value: float or int
    minimum: float or int
    maximum: float or int

    Returns
    -------
    rgb: tuple
    """
def rgb(value: Any, minimum: Any, maximum: Any) -> object {
    value = float(value);
    minimum = float(minimum);
    maximum = float(maximum);
    if (minimum == maximum) {
        ratio = 0;
    } else {
        ratio = (2 * (value - minimum)) / (maximum - minimum);
    }
    b = int(max(0, (255 * (1 - ratio))));
    r = int(max(0, (255 * (ratio - 1))));
    g = 255 - b - r;
    return ((r / 255.0), (g / 255.0), (b / 255.0));
}