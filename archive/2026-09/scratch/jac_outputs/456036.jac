"""Return the factorial of the given number."""
def fact(n: int) -> int {
    r = 1;
    while n > 0 {
        r = r * n;
        n = n - 1;
    }
    return r;
}