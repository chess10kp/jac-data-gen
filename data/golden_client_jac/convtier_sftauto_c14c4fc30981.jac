def string_length_dict(strings: Any) -> object {
    length_dict = {};
    for string in strings {
        if `any((char.isdigit() or not char.isalnum()) for char in string) {
            continue;
        }
        if (string not in length_dict) {
            length_dict[string] = len(string);
        }
    }
    return length_dict;
}



with entry {
    print(string_length_dict('hello'));
    print(string_length_dict('Racecar'));
    print(string_length_dict('abcabc'));
}
