def split_string_to_uppercase_chars(string: Any) -> object {
    uppercase_chars = [];
    for char in string {
        if char.isupper() {
            uppercase_chars.append(char);
        }
    }
    return uppercase_chars;
}



with entry {
    print(split_string_to_uppercase_chars('hello'));
    print(split_string_to_uppercase_chars('Racecar'));
    print(split_string_to_uppercase_chars('Hello, World!'));
}
