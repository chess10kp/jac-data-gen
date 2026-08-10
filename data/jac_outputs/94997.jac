"""Return the n-th Fibonacci number."""
def Fib(n: int) -> int {
    assert `type(n) is int and n >= 0, "ERROR (Fib): index should be positive and integer!";
    return Fib(n - 1) + Fib(n - 2) if n > 1 else 1 if n is 1 else 0;
}