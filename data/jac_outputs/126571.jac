"""Shift left n bits (zeros come in from the right)
    >>> shl(0.5, 1)
    1.0
    >>> shl(0.1, 1)
    0.2
    """
def shl(x: Any, n: Any) -> object {
    return (x * (2 ** n));
}