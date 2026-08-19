def sum_of_prime_factors(N: Any) -> object {
    sum = 0;
    i = 2;
    while (N > 1) {
        if ((N % i) == 0) {
            sum += i;
            N /= i;
        } else {
            i += 1;
        }
    }
    return sum;
}



with entry {
    print(sum_of_prime_factors(5));
    print(sum_of_prime_factors(10));
    print(sum_of_prime_factors(2));
}
