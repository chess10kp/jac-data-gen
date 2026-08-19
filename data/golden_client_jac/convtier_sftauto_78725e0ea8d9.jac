def sieve_of_eratosthenes(n: Any) -> object {
    primes = [True] * (n + 1);
    primes[0] = primes[1]=False;
    p = 2;
    while ((p * p) <= n) {
        if primes[p] {
            for i in range((p * p), (n + 1), p) {
                primes[i] = False;
            }
        }
        p += 1;
    }
    return [
        i
        for i in range((n + 1))
        if primes[i]
    ];
}



with entry {
    print(sieve_of_eratosthenes(5));
    print(sieve_of_eratosthenes(10));
    print(sieve_of_eratosthenes(2));
}
