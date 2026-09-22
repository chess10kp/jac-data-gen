"""Split at position k and swap halves."""
def r3(a: list, k: int) -> list {
    n = len(a);
    k = k % n;
    return a[(n - k):] + a[:(n - k)];
}