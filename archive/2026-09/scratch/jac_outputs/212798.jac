"""Return the product of n * (n - 2) * (n - 4) * ...

    >>> skip_mul(5) # 5 * 3 * 1
    15
    >>> skip_mul(8) # 8 * 6 * 4 * 2  * 0
    0
    """
def skip_mul(n: int) -> int {
    if n == 0 {
        return 0;
    }
    return n * skip_mul(n - 2);
}