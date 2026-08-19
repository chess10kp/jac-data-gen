def sieve_of_eratosthenes(limit: Any) -> object {
    primes = [True] * (limit + 1);
    primes[0] = primes[1]=False;
    p = 2;
    while ((p * p) <= limit) {
        if primes[p] {
            for i in range((p * p), (limit + 1), p) {
                primes[i] = False;
            }
        }
        p += 1;
    }
    return [
        num
        for (num, is_prime) in enumerate(primes)
        if is_prime
    ];
}



with entry {
    print(sieve_of_eratosthenes(5));
    print(sieve_of_eratosthenes(10));
    print(sieve_of_eratosthenes(2));
}
