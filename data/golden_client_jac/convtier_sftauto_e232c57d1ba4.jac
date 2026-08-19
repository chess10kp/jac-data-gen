def check_unique_chars(string: Any) -> object {
    char_set = `set();
    for char in string {
        if (char in char_set) {
            return False;
        }
        char_set.add(char);
    }
    return True;
}



with entry {
    print(check_unique_chars('hello'));
    print(check_unique_chars([]));
}
