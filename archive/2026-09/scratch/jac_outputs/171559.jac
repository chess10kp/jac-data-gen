"""!
    Saturates the input value in the given interval
    @param x: value to saturate
    @param xmin: minimum value of the interval
    @param xmax: maximum value of the interval
    @return: saturated value
    """
def sat(x: Any, xmin: Any, xmax: Any) -> object {
    if (x > xmax) {
        return xmax;
    }
    if (x < xmin) {
        return xmin;
    }
    return x;
}