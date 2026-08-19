def get_prime_numbers(lst: Any) -> object {
    primes = [];
    for num in lst {
        if (num > 1) {
            for i in range(2, (int((num / 2)) + 1)) {
                if ((num % i) == 0) {
                    break;
                }
            } else {
                primes.append(num);
            }
        }
    }
    return primes;
}



with entry {
    print(get_prime_numbers([81]));
    print(get_prime_numbers([-8, -4, 2]));
    print(get_prime_numbers([-2, -1, 4, 7]));
}
