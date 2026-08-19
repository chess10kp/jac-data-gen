def get_digit_sum(num: Any) -> object {
    return sum(int(digit) for digit in str(num));
}



with entry {
    print(get_digit_sum(5));
    print(get_digit_sum(10));
    print(get_digit_sum(2));
}
