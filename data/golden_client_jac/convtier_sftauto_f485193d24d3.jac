def to_upper_case(s: Any) -> object {
    upper_case = "";
    for char in s {
        char_code = ord(char);
        if (97 <= char_code <= 122) {
            char_code -= 32;
        }
        upper_case += chr(char_code);
    }
    return upper_case;
}



with entry {
    print(to_upper_case('hello'));
    print(to_upper_case('Racecar'));
    print(to_upper_case('abcabc'));
}
