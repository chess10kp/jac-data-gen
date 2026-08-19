def is_palindrome(string: Any) -> object {
    n = len(string);
    for i in range((n // 2)) {
        if (string[i] != string[(n - 1 - i)]) {
            return False;
        }
    }
    return True;
}



with entry {
    print(is_palindrome('hello'));
    print(is_palindrome('level'));
}
