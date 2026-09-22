"""Returns the sum of all integers in the range ``[a, b]``, i.e. from ``a`` to
    ``b`` inclusive.

    See

    - https://math.stackexchange.com/questions/1842152/finding-the-sum-of-numbers-between-any-two-given-numbers
    """
def sum_of_integers_in_inclusive_range(a: int, b: int) -> int {
    int((b - a + 1) * (a + b) / 2)
}