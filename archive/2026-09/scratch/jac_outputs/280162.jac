"""Compute the base 2 logarithm of n."""
def log2(n: int) -> int {
    l = 0;
    while n > 1 {
        n = n >> 1;
        l = l + 1;
    }
    return l;
}