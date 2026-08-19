def binary_to_decimal(binary: Any) -> object {
    if (binary == '0') {
        return 0;
    }
    length = len(binary);
    decimal = 0;
    for i in range(length) {
        if (binary[i] == '1') {
            decimal += 2 ** (length - i - 1);
        }
    }
    return decimal;
}



with entry {
    print(binary_to_decimal('hello'));
}
