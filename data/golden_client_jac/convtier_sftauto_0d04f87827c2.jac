def prime_factors(num: Any) -> object {
    factors = [];
    i = 2;
    while (i <= num) {
        if ((num % i) == 0) {
            factors.append(i);
            num = num / i;
        } else {
            i += 1;
        }
    }
    return factors;
}



with entry {
    print(prime_factors(5));
    print(prime_factors(10));
    print(prime_factors(2));
}
