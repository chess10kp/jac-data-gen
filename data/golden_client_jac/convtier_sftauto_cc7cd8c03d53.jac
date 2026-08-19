def is_narcissistic_number(num: Any) -> object {
    num_str = str(num);
    num_digits = len(num_str);
    total_sum = 0;
    for digit in num_str {
        total_sum += int(digit) ** num_digits;
    }
    return (total_sum == num);
}



with entry {
    print(is_narcissistic_number(5));
    print(is_narcissistic_number(10));
}
