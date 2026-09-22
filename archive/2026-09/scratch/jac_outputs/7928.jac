"""Print the Fibonacci series up to n."""
def fib(n: int) -> list[int] {
    (a, b) = (0, 1);
    c = [];
    while b < n {
        c.append(b);
        (a, b) = (b, a + b);
    }
    return c;
}