def convert_to_string(char_array: Any) -> object {
    result = '';
    for char in char_array {
        if char.isalpha() {
            result += char;
        }
    }
    return result;
}



with entry {
    print(convert_to_string('hello'));
    print(convert_to_string('Racecar'));
    print(convert_to_string('abcabc'));
}
