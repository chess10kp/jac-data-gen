"""Return factorial.

    Args:
        n (int): Argument (non-negative)

    Returns:
        Factorial of n
    """
def factorial(n: int) -> int {
    assert type(n) == int and n >= 0;
    if n == 0 {
        return 1;
    }
    return n * factorial(n - 1);
}