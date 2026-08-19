def is_palindrome(s: Any) -> object {
    length = len(s);
    for i in range((length // 2)) {
        if (s[i] != s[(length - i - 1)]) {
            return False;
        }
    }
    return True;
}



with entry {
    print(is_palindrome('hello'));
    print(is_palindrome('level'));
}
