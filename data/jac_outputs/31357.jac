"""Returns the nth Fibonacci number."""
def fib(n: int) -> int {
    if n < 2 {
        return n;
    }
    return fib(n - 2) + fib(n - 1);
}