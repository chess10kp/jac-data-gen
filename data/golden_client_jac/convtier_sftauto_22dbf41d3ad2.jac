def sieve_of_eratosthenes(n: Any) -> object {
    primes = [True] * (n + 1);
    primes[0] = primes[1]=False;
    for p in range(2, (int((n ** 0.5)) + 1)) {
        if (primes[p] == True) {
            for i in range((p * p), (n + 1), p) {
                primes[i] = False;
            }
        }
    }
    return [
        i
        for i in range(2, (n + 1))
        if primes[i]
    ];
}



with entry {
    print(sieve_of_eratosthenes(5));
    print(sieve_of_eratosthenes(10));
    print(sieve_of_eratosthenes(2));
}
