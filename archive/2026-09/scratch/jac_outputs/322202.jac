"""Convert a Roman numeral string to an integer."""
def roman_to_int(s: str) -> int {
    integer_value = 0;
    for (index, char) in enumerate(s) {
        if char == "I" {
            integer_value += 1;
        } elif char == "V" {
            integer_value += 5;
        } elif char == "X" {
            integer_value += 10;
        } elif char == "L" {
            integer_value += 50;
        } elif char == "C" {
            integer_value += 100;
        } elif char == "D" {
            integer_value += 500;
        } elif char == "M" {
            integer_value += 1000;
        }
        if index >= 1 and s[index - 1] == "I" and char in ("X", "V") {
            integer_value -= 2;
        }
        if index >= 1 and s[index - 1] == "X" and char in ("L", "C") {
            integer_value -= 20;
        }
        if index >= 1 and s[index - 1] == "C" and char in ("M", "D") {
            integer_value -= 200;
        }
    }
    print(integer_value);
    return integer_value;
}