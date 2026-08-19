def filter_primes(numbers: Any) -> object {
    def is_prime(n: Any) -> object {
        if (n < 2) {
            return False;
        }
        for i in range(2, (int((n ** 0.5)) + 1)) {
            if ((n % i) == 0) {
                return False;
            }
        }
        return True;
    }
    primes = [];
    for number in numbers {
        if (is_prime(number) and (number not in primes)) {
            primes.append(number);
        }
    }
    return sorted(primes);
}



with entry {
    print(filter_primes([-9]));
    print(filter_primes([-8, -4, 2, 6]));
    print(filter_primes([4, 7, -1, 9, -2]));
}
