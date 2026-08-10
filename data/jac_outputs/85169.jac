"""
    >>> lrange(3)
    [0, 1, 2]
    >>> lrange(1, 3)
    [1, 2]
    >>> lrange(0, 3, 2)
    [0, 2]
    """
def lrange(*args: int, **kwargs: int) -> list[int] {
    return list(range(*args, **kwargs));
}