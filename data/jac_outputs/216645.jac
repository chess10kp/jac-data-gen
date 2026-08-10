"""
    Miller-Rabin test with base a

    Args:
        n (int): number to test
        a (int): base

    Returns:
        bool: result
    """
def _MillerRabin(n: int, a: int) -> bool {
    d = n - 1;
    while (d & 1) == 0 {
        d >>= 1;
    }
    t = pow(a, d, n);
    while d != n - 1 and t != n - 1 and t != 1 {
        t = (t * t) % n;
        d <<= 1;
    }
    return t == n - 1 or (d & 1) == 1;
}