def is_empty(string: Any) -> object {
    string = string.strip();
    if (len(string) == 0) {
        return True;
    }
    for char in string {
        if (not char.isspace() and not char.isalnum()) {
            return True;
        }
    }
    return False;
}



with entry {
    print(is_empty('hello'));
    print(is_empty('Hello, World!'));
}
