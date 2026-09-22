"""Return the value of G(n), computed recursively."""
def g(n: int) -> int {
    if n <= 3 {
        return n;
    }
    return g(n - 1) + 2 * g(n - 2) + 3 * g(n - 3);
}