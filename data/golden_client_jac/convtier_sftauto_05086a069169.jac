def binary_to_decimal(binary: Any) -> object {
    decimal = 0;
    for digit in binary {
        decimal = decimal * 2;
        if (digit == '1') {
            decimal = decimal + 1;
        }
    }
    return decimal;
}



with entry {
    print(binary_to_decimal('hello'));
}
