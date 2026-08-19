def sieve_of_eratosthenes(n: Any) -> object {
    is_prime = [True] * (n + 1);
    is_prime[0] = is_prime[1]=False;
    p = 2;
    while ((p * p) <= n) {
        if is_prime[p] {
            for i in range((p * p), (n + 1), p) {
                is_prime[i] = False;
            }
        }
        p += 1;
    }
    return is_prime;
}



with entry {
    print(sieve_of_eratosthenes(5));
    print(sieve_of_eratosthenes(10));
    print(sieve_of_eratosthenes(2));
}
