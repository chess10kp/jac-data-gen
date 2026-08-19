def generate_prime_numbers(n: Any) -> object {
    prime_numbers = [];
    for num in range(2, (n + 1)) {
        is_prime = True;
        for i in range(2, (int((num ** 0.5)) + 1)) {
            if ((num % i) == 0) {
                is_prime = False;
                break;
            }
        }
        if is_prime {
            prime_numbers.append(num);
        }
    }
    return prime_numbers;
}



with entry {
    print(generate_prime_numbers(5));
    print(generate_prime_numbers(10));
    print(generate_prime_numbers(2));
}
