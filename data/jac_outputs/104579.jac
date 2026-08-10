"""Assumes x is an int >= 0; returns Fibonacci of x."""
def fib(x: int) -> int {
    if x == 0 or x == 1 {
        return 1;
    }
    return fib(x - 1) + fib(x - 2);
}