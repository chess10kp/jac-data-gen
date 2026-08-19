def is_valid_key(key: Any) -> object {
    return not `any((char.isdigit() or not char.isalpha()) for char in key);
}



with entry {
    print(is_valid_key('hello'));
    print(is_valid_key('Hello, World!'));
}
