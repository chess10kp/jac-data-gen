"""Return a list containing the Fibonacci series up to n."""
def fib2(n: int) -> list[int] {
    result = [];
    (a, b) = (0, 1);
    while a < n {
        result.append(a);
        (a, b) = (b, a + b);
    }
    return result;
}