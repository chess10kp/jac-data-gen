def sieve_of_eratosthenes(limit: Any) -> object {
    primes = [True] * (limit + 1);
    primes[0] = primes[1]=False;
    for i in range(2, (int((limit ** 0.5)) + 1)) {
        if primes[i] {
            for j in range((i * i), (limit + 1), i) {
                primes[j] = False;
            }
        }
    }
    return [
        i
        for i in range((limit + 1))
        if primes[i]
    ];
}



with entry {
    print(sieve_of_eratosthenes(5));
    print(sieve_of_eratosthenes(10));
    print(sieve_of_eratosthenes(2));
}
