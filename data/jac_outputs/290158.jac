"""Returns the n_th pentagonal number. If fed with a negative number, it returns an
    extended pentagonal number.
    """
def pentagonal(n: int) -> int {
    n * (3 * n - 1) // 2
}