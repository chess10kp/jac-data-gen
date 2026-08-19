def sum_of_digit_squares(num: Any) -> object {
    sum = 0;
    while (num > 0) {
        digit = num % 10;
        sum += digit ** 2;
        num //= 10;
    }
    return sum;
}



with entry {
    print(sum_of_digit_squares(5));
    print(sum_of_digit_squares(10));
    print(sum_of_digit_squares(2));
}
