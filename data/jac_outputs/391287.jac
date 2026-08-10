"""Simple implementation of math.comb for python 3.7 compatibility."""
def choose(n: int, k: int) -> int {
    if 0 <= k <= n {
        ntok = 1;
        ktok = 1;
        for t in range(1, min(k, n - k) + 1) {
            ntok *= n;
            ktok *= t;
            n -= 1;
        }
        return ntok // ktok;
    }
    return 0;
}