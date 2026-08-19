def append_character(string: Any) -> object {
    if (len(string) < 3) {
        return "Input string should be at least 3 characters long.";
    }
    if not string.isalpha() {
        return "Input string should only contain alphabets.";
    }
    start_char = string[0];
    result = start_char + string + start_char;
    return result;
}



with entry {
    print(append_character('hello'));
    print(append_character('Racecar'));
    print(append_character('abcabc'));
}
