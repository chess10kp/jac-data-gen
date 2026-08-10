"""
    Binomial coefficients, thanks to Andrew Dalke.
    """
def binomial(n: int, k: int) -> int {
    if 0 <= k <= n {
        n_tok = 1;
        k_tok = 1;
        for t in range(1, min(k, n - k) + 1) {
            n_tok *= n;
            k_tok *= t;
            n -= 1;
        }
        return n_tok // k_tok;
    } else {
        return 0;
    }
}