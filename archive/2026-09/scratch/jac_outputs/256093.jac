""" parses string_value and returns only number-like part
"""
def get_numeric_value(string_value: str) -> str {
    num_chars = ['.', '+', '-'];
    number = '';
    for c in string_value {
        if c.isdigit() or c in num_chars {
            number += c;
        }
    }
    return number;
}