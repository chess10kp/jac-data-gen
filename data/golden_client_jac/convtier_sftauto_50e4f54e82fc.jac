def sum_of_digits(num: Any) -> object {
    num_str = str(num);
    sum = 0;
    for digit in num_str {
        digit_int = int(digit);
        if ((digit_int % 3) != 0) {
            sum += digit_int;
        }
    }
    return sum;
}



with entry {
    print(sum_of_digits(5));
    print(sum_of_digits(10));
    print(sum_of_digits(2));
}
