"""Build up number, taking modulo as you go. Slow but simple."""
def alt1(n: int, m: int) -> int {
    mod = 10 ** m;
    res = 1;
    for _ in range(n) {
        res = (res << 1) % mod;
    }
    return res;
}