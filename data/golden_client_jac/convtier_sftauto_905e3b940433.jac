def find_primes(n: Any) -> object {
    primes = [];
    sieve = [True] * (n + 1);
    for num in range(2, (n + 1)) {
        if sieve[num] {
            primes.append(num);
            for i in range(num, (n + 1), num) {
                sieve[i] = False;
            }
        }
    }
    return primes;
}



with entry {
    print(find_primes(5));
    print(find_primes(10));
    print(find_primes(2));
}
