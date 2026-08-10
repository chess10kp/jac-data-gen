"""Return a list of the primes below n."""
def sieve5(n: int) -> list[int] {
    prime = [True] * n;
    result = [2];
    append = result.append;
    sqrt_n = int(n ** 0.5) + 1 | 1;
    for p in range(3, sqrt_n, 2) {
        if prime[p] {
            append(p);
            prime[(p * p)::(2 * p)] = [False] * (((n - (p * p) - 1) // (2 * p)) + 1);
        }
    }
    for p in range(sqrt_n, n, 2) {
        if prime[p] {
            append(p);
        }
    }
    return result;
}