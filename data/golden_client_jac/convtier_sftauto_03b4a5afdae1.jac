def is_prime(n: Any) -> object {
    if (n < 2) {
        return False;
    }
    sieve = [True] * (n + 1);
    sieve[0] = sieve[1]=False;
    for i in range(2, (int((n ** 0.5)) + 1)) {
        if sieve[i] {
            for j in range((i * i), (n + 1), i) {
                sieve[j] = False;
            }
        }
    }
    return sieve[n];
}



with entry {
    print(is_prime(5));
    print(is_prime(10));
}
