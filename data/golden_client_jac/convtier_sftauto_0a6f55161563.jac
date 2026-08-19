def extract_digits(num: Any) -> object {
    digits = [];
    divisor = 1;
    while ((num // divisor) > 9) {
        divisor *= 10;
    }
    while (divisor >= 1) {
        digit = num // divisor;
        digits.append(digit);
        num %= divisor;
        divisor //= 10;
    }
    return digits;
}



with entry {
    print(extract_digits(5));
    print(extract_digits(10));
    print(extract_digits(2));
}
