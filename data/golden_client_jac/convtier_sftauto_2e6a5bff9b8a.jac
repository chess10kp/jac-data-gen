def remove_trailing_spaces(input_string: Any) -> object {
    i = len(input_string) - 1;
    while ((i >= 0) and (input_string[i] == ' ')) {
        i -= 1;
    }
    return input_string[:(i + 1)];
}



with entry {
    print(remove_trailing_spaces('hello'));
    print(remove_trailing_spaces('Racecar'));
    print(remove_trailing_spaces('abcabc'));
}
