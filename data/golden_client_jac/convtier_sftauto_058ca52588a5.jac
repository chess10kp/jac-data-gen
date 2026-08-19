def convert_octal_to_binary(octal_number: Any) -> object {
    if (octal_number == 0) {
        return 0;
    } else {
        last_digit = octal_number % 10;
        decimal_equivalent = last_digit * (8 ** 0);
        binary_equivalent = convert_octal_to_binary((octal_number // 10));
        binary_number = (binary_equivalent * (10 ** 1)) + decimal_equivalent;
        return binary_number;
    }
}



with entry {
    print(convert_octal_to_binary(0));
}
