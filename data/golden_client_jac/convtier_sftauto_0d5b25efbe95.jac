def access_second_character(string: Any) -> object {
    second_char = string[1];
    return second_char;
}



with entry {
    print(access_second_character('hello'));
    print(access_second_character('Racecar'));
    print(access_second_character('abcabc'));
}
