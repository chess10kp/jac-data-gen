def largest_prime_factor(number: Any) -> object {
    i = 2;
    while ((i * i) <= number) {
        if (number % i) {
            i += 1;
        } else {
            number //= i;
        }
    }
    if (number > 1) {
        return number;
    }
    return i;
}



with entry {
    print(largest_prime_factor(5));
    print(largest_prime_factor(2));
    print(largest_prime_factor(7));
}
