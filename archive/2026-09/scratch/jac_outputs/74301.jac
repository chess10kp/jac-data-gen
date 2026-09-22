"""integer kth root of n"""
def integer_root(n: int, k: int) -> int {
    (u, s) = (n, (n + 1));
    while u < s {
        s = u;
        t = ((k - 1) * s) + (n // pow(s, (k - 1)));
        u = t // k;
    }
    return s;
}