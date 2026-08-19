def roman_to_decimal(numeral: Any) -> object {
    roman_map = {'I': 1, 'V': 5, 'X': 10, 'L': 50, 'C': 100, 'D': 500, 'M': 1000};
    decimal = 0;
    prev_value = 0;
    for symbol in reversed(numeral) {
        value = roman_map[symbol];
        if (value < prev_value) {
            decimal -= value;
        } else {
            decimal += value;
            prev_value = value;
        }
    }
    return decimal;
}



with entry {
    print(roman_to_decimal([]));
}
