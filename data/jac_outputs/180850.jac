"""Finds all the primes below number n using the sieve of Eratosthenes."""
def find_primes(n: int) -> list[int] {
    candidates = [(i + 2) for i in range(n - 1)];
    for p in candidates {
        for i in candidates {
            if i % p == 0 and p != i {
                candidates.remove(i);
            }
        }
    }
    return candidates;
}