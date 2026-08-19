def sum_of_digits(n: Any) -> object {
    if (n == 0) {
        return 0;
    }
    digit_sum = 0;
    while (n > 0) {
        digit = n % 10;
        digit_sum += digit;
        n //= 10;
    }
    return digit_sum;
}



with entry {
    print(sum_of_digits(5));
    print(sum_of_digits(10));
    print(sum_of_digits(2));
}
