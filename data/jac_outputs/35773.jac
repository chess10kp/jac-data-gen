"""Calculates the n-th Fabonacci number iteratively

    >>> fib(0)
    0

    >>> fib(1)
    1

    >>> fib(10)
    55

    """
def fib(n: int) -> int {
    (a, b) = (0, 1);
    for i in range(n) {
        (a, b) = (b, a + b);
    }
    return a;
}