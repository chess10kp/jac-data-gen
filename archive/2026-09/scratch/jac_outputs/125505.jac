"""
    round the given price to the nearest tick
    >>> tick(100.03)
    100.05
    >>> tick(101.31, 0.5)
    101.5
    >>> tick(101.04, 0.1)
    101.0
    >>> tick(100.01,0.1)
    100.0
    """
def tick(price: float, tick_size: float = 0.05) -> float {
    return round((round((price / tick_size)) * tick_size), 2);
}