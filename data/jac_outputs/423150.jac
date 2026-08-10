"""Fibonacci iterativa."""
def fib_iterativa(number: int) -> int {
    last = 0;
    curr = 1;
    for _ in range(number) {
        (last, curr) = (curr, curr + last);
    }
    return last;
}