"""
    Returns the first element of an iterable X.
    """
def first(X: list[int]) -> int {
    next(iter(X))
}