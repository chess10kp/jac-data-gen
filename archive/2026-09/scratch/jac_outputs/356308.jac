"""Return prime sieve results for n, or None when n < 2."""
def series(n: int, bool: bool = False) -> list[bool] | list[int] | None {
    if n < 2 {
        return None;
    }
    prime = [True] * (n + 1);
    p = 2;
    while p * p <= n {
        if prime[p] {
            for i in range(p * 2, n + 1, p) {
                prime[i] = False;
            }
        }
        p += 1;
    }
    if bool {
        return prime;
    }
    return [i for i in range(2, n + 1) if prime[i]];
}