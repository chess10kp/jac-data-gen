def change_case(string: Any) -> object {
    result = "";
    for char in string {
        ascii_value = ord(char);
        if ((ascii_value >= 65) and (ascii_value <= 90)) {
            ascii_value += 32;
        } elif ((ascii_value >= 97) and (ascii_value <= 122)) {
            ascii_value -= 32;
        }
        result += chr(ascii_value);
    }
    return result;
}



with entry {
    print(change_case('hello'));
    print(change_case('Racecar'));
    print(change_case('abcabc'));
}
