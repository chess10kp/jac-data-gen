def find_ascii_code(string: Any) -> object {
    for char in string {
        if (char == 'X') {
            return (ord(char) - ord('0'));
        }
    }
    return -1;
}



with entry {
    print(find_ascii_code('hello'));
}
