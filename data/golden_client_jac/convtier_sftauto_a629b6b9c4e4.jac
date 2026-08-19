def sieve_of_eratosthenes(n: Any) -> object {
    prime = [True] * (n + 1);
    prime[0] = prime[1]=False;
    p = 2;
    while ((p * p) <= n) {
        if prime[p] {
            for i in range((p * p), (n + 1), p) {
                prime[i] = False;
            }
        }
        p += 1;
    }
    return prime;
}



with entry {
    print(sieve_of_eratosthenes(5));
    print(sieve_of_eratosthenes(10));
    print(sieve_of_eratosthenes(2));
}
