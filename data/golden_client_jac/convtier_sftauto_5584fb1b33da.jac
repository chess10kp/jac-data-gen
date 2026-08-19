def string_to_list(string: Any) -> object {
    char_list = [];
    for i in range(len(string)) {
        char_list.append(string[i]);
    }
    return char_list;
}



with entry {
    print(string_to_list('hello'));
    print(string_to_list('Racecar'));
    print(string_to_list('abcabc'));
}
