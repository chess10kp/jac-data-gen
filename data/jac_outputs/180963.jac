"""Get the Nth Fibonacci number, cache intermediate results in Redis."""
def fib(number: int) -> int {
    if number < 0 {
        raise ValueError;
    }
    if number in (0, 1) {
        return number;
    }
    return fib(number - 1) + fib(number - 2);
}