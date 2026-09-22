"""Returns the nth Fibonacci number in the Fibonacci sequence."""
def fibonacci_recursive(number: int) -> int {
    if number in (0, 1) {
        return number;
    }
    return fibonacci_recursive(number - 1) + fibonacci_recursive(number - 2);
}