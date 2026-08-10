"""
Write a function to convert a string into an integer.
Return None if string is an invalid integer.
"""
def solution(string: str) -> int | None {
    number_value = {
        '0': 0,
        '1': 1,
        '2': 2,
        '3': 3,
        '4': 4,
        '5': 5,
        '6': 6,
        '7': 7,
        '8': 8,
        '9': 9
    };
    is_negative = False;
    result = 0;
    for (count, char) in enumerate(string) {
        value = number_value.get(char);
        if count == 0 and char == '-' {
            is_negative = True;
        } elif value is None {
            return value;
        } else {
            result *= 10;
            result += value;
        }
    }
    if is_negative {
        return result * -1;
    }
    return result;
}