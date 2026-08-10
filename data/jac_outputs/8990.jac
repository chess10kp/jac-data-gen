"""
    Return the nth fibonacci number, that is n if n < 2,
    or fibonacci(n-2) + fibonacci(n-1) otherwise.
    """
def fibonacci(n: int) -> int {
    if n < 2 {
        return n;
    }
    return fibonacci(n - 2) + fibonacci(n - 1);
}