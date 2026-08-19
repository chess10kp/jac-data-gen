def get_primes(n: Any) -> object {
    primes = [];
    sieve = [True] * (n + 1);
    p = 2;
    while ((p ** 2) <= n) {
        if sieve[p] {
            primes.append(p);
            for i in range((p ** 2), (n + 1), p) {
                sieve[i] = False;
            }
        }
        p += 1;
    }
    return primes;
}



with entry {
    print(get_primes(5));
    print(get_primes(10));
    print(get_primes(2));
}
