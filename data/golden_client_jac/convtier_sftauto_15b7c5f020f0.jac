def is_palindrome(string: Any) -> object {
    string = string.lower();
    string = ''.join(
        char
        for char in string
        if char.isalnum()
    );
    for i in range((len(string) // 2)) {
        if (string[i] != string[(-i - 1)]) {
            return False;
        }
    }
    return True;
}



with entry {
    print(is_palindrome('hello'));
    print(is_palindrome('Racecar'));
}
