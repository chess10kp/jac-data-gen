def has_unique_chars(string: Any) -> object {
    if (len(string) > 128) {
        return False;
    }
    char_set = [False] * 128;
    for char in string {
        if char_set[ord(char)] {
            return False;
        }
        char_set[ord(char)] = True;
    }
    return True;
}



with entry {
    print(has_unique_chars('hello'));
}
