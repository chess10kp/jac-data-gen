def is_valid_string(string: Any) -> object {
    return string.isalpha();
}



with entry {
    print(is_valid_string('hello'));
    print(is_valid_string('Hello, World!'));
}
