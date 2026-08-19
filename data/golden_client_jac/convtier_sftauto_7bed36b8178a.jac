def is_unique(string: Any) -> object {
    char_count = {};
    for char in string {
        if (char in char_count) {
            return False;
        }
        char_count[char] = 1;
    }
    return True;
}



with entry {
    print(is_unique('hello'));
    print(is_unique([]));
}
