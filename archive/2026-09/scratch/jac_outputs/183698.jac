"""Return pair of Fibonacci numbers, F(n) and F(n-1)."""
def good_fibonacci(n: int) -> tuple[int, int] {
    if n <= 1 {
        return (n, 0);
    }
    (a, b) = good_fibonacci(n - 1);
    return (a + b, a);
}