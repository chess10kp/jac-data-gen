"""Convert a roman numeral to integer."""
def integer(roman: str) -> int {
    symbol_value = {'M': 1000, 'D': 500, 'C': 100, 'L': 50, 'X': 10, 'V': 5, 'I': 1};
    second_last_index = len(roman) - 1;
    result = 0;
    for i in range(second_last_index) {
        present_value = symbol_value[roman[i]];
        next_value = symbol_value[roman[i + 1]];
        if present_value < next_value {
            result -= present_value;
        } else {
            result += present_value;
        }
    }
    result += symbol_value[roman[-1]];
    return result;
}