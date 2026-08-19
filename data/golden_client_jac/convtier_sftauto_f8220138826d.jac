def binary_to_decimal(binary_string: Any) -> object {
    decimal = 0;
    for i in range(len(binary_string)) {
        decimal = (
            decimal + (int(binary_string[i]) * (2 ** (len(binary_string) - i - 1)))
        );
    }
    return decimal;
}



with entry {
    print(binary_to_decimal([1, 2, 4]));
    print(binary_to_decimal([1, 2]));
    print(binary_to_decimal([5, 5, 5]));
}
