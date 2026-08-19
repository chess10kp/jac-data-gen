def prime_factors(num: Any) -> object {
    factors = [];
    i = 2;
    while ((i * i) <= num) {
        if (num % i) {
            i += 1;
        } else {
            num //= i;
            factors.append(i);
        }
    }
    if (num > 1) {
        factors.append(num);
    }
    return factors;
}



with entry {
    print(prime_factors(5));
    print(prime_factors(10));
    print(prime_factors(2));
}
