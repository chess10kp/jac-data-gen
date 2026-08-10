"""Calculate factorial of n number."""
def factorial(n: int) -> int {
    assert n >= 0, "negative factorial not recognized";
    if n == 0 {
        return 1;
    }
    return factorial(n - 1) * n;
}