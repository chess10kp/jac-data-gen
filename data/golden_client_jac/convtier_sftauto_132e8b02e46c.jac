def filter_primes(numbers: Any) -> object {
    primes = [];
    for num in numbers {
        if (num <= 1) {
            continue;
        }
        is_prime = True;
        for i in range(2, (int((num ** 0.5)) + 1)) {
            if ((num % i) == 0) {
                is_prime = False;
                break;
            }
        }
        if is_prime {
            primes.append(num);
        }
    }
    return primes;
}



with entry {
    print(filter_primes([81]));
    print(filter_primes([-8, -4, 2]));
    print(filter_primes([-2, -1, -4, 7]));
}
