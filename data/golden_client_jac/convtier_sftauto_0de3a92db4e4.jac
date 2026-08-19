def prime_factorization(num: Any) -> object {
    factors = [];
    divisor = 2;
    while (divisor <= num) {
        if ((num % divisor) == 0) {
            factors.append(divisor);
            num = num / divisor;
        } else {
            divisor += 1;
        }
    }
    return factors;
}



with entry {
    print(prime_factorization(5));
    print(prime_factorization(10));
    print(prime_factorization(2));
}
