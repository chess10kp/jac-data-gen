def string_to_list(string: Any) -> object {
    char_list = [];
    for char in string {
        if (char != ' ') {
            char_list.append(char);
        }
    }
    return char_list;
}



with entry {
    print(string_to_list('hello'));
    print(string_to_list('Racecar'));
    print(string_to_list('abcabc'));
}
