def count_digit_only_primes(n: Any) -> object {
    count = 0;
    for i in range(1, (n + 1)) {
        if (((n % i) == 0) and is_prime(i)) {
            count += 1;
        }
    }
    return count;
}



with entry {
    print(count_digit_only_primes(0));
}
