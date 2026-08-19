def is_isogram(s: Any) -> object {
    char_count = {};
    for char in s.lower() {
        if char.isalpha() {
            if (char in char_count) {
                return False;
            }
            char_count[char] = char_count.get(char, 0) + 1;
        }
    }
    return (True, char_count);
}



with entry {
    print(is_isogram('hello'));
}
