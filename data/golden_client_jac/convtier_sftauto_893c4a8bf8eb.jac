def binary_to_decimal(binary_string: Any) -> object {
    if (not binary_string or not all((char in ('0', '1')) for char in binary_string)) {
        return "Invalid binary string";
    }
    decimal_value = int(binary_string, 2);
    return decimal_value;
}



with entry {
    print(binary_to_decimal('hello'));
}
