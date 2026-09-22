"""
    a = (y2- y1) / (x2 -x1)
    b = y1 - ax1
    Return
    y = ax + b
    ----------
    a: float
    b: float
    """
def primary_function(x1: Any, y1: Any, x2: Any, y2: Any) -> object {
    a = (y2 - y1) / (x2 - x1);
    b = y1 - (a * x1);
    return [a, b];
}