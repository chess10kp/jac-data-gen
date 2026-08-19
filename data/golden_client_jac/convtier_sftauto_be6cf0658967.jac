def binary_to_decimal(binary_string: Any) -> object {
    decimal = 0;
    power = len(binary_string) - 1;
    for digit in binary_string {
        decimal += int(digit) * (2 ** power);
        power -= 1;
    }
    return decimal;
}



with entry {
    print(binary_to_decimal([]));
}
