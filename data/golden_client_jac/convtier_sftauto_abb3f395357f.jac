def binary_to_decimal(binary: Any) -> object {
    decimal = 0;
    power = 0;
    for i in range((len(binary) - 1), -1, -1) {
        if (binary[i] == '1') {
            decimal += 2 ** power;
        }
        power += 1;
    }
    return decimal;
}



with entry {
    print(binary_to_decimal('hello'));
}
