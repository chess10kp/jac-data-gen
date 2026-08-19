def get_digits_sum(num: Any) -> object {
    return sum(int(digit) for digit in str(num));
}



with entry {
    print(get_digits_sum(5));
    print(get_digits_sum(10));
    print(get_digits_sum(2));
}
