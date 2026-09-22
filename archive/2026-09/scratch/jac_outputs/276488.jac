"""Returns all primess up to upper_bound (exclusive) using the sieve of Eratosthenes."""
def find_primes_sieve(upper_bound: int) -> list[int] {
    is_prime = [1] * upper_bound;
    primes = [];
    for n in range(2, upper_bound) {
        if not is_prime[n] {
            continue;
        }
        primes.append(n);
        if n * n <= upper_bound {
            m = 2 * n;
            while m < upper_bound {
                is_prime[m] = 0;
                m += n;
            }
        }
    }
    return primes;
}