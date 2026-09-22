"""Computes the Fibonacci sequence at point v."""
def fibonacci(v: int) -> int {
    if v == 0 {
        return 0;
    }
    if v == 1 {
        return 1;
    }
    return fibonacci(v - 1) + fibonacci(v - 2);
}