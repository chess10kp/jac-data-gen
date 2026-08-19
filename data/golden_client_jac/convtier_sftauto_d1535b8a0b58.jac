def is_palindrome(s: Any) -> object {
    for i in range(len(s)) {
        if (s[i] != s[(len(s) - i - 1)]) {
            return False;
        }
    }
    return True;
}



with entry {
    print(is_palindrome('hello'));
    print(is_palindrome('level'));
}
