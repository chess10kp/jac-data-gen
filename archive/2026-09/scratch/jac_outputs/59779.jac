"""Compute the nth fibonacci number recursively."""
def fibonacci(n: int) -> int {
    if n == 1 or n == 2 {
        return 1;
    }
    return fibonacci(n - 1) + fibonacci(n - 2);
}