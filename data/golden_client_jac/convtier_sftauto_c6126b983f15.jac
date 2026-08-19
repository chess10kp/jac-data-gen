def get_first_n_primes(n: Any) -> object {
    primes = [];
    is_prime = [True] * (n + 1);
    for num in range(2, (int((n ** 0.5)) + 1)) {
        if is_prime[num] {
            for multiple in range((num * num), (n + 1), num) {
                is_prime[multiple] = False;
            }
        }
    }
    for num in range(2, (n + 1)) {
        if is_prime[num] {
            primes.append(num);
        }
    }
    return primes[:1000];
}



with entry {
    print(get_first_n_primes(5));
    print(get_first_n_primes(10));
    print(get_first_n_primes(2));
}
