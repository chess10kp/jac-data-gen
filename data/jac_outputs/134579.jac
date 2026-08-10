"""
    Returns smallest x > 0 s.t. pow(a, x, mod) == b or None if no such x exists.
    Note: works even if a and mod are not coprime.
    """
def discrete_log(a: Any, b: Any, mod: Any) -> object {
    n = int((mod ** 0.5)) + 1;
    (tiny_step, e) = ({}, 1);
    for j in range(1, (n + 1)) {
        e = (e * a) % mod;
        if (e == b) {
            return j;
        }
        tiny_step[((b * e) % mod)] = j;
    }
    factor = e;
    for i in range(2, (n + 2)) {
        e = (e * factor) % mod;
        if (e in tiny_step) {
            j = tiny_step[e];
            return ((n * i) - j) if (pow(a, ((n * i) - j), mod) == b) else None;
        }
    }
}