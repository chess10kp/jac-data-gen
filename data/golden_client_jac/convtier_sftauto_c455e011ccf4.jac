def sum_primes(n: Any) -> object {
    if (n <= 1) {
        return 0;
    }
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
    return sum(
        i
        for i in range(2, (n + 1))
        if is_prime[i]
    );
}



with entry {
    print(sum_primes(5));
    print(sum_primes(10));
    print(sum_primes(2));
}
