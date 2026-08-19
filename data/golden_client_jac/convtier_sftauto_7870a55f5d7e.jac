def is_palindrome(string: Any) -> object {
    length = len(string);
    for i in range((length // 2)) {
        if (string[i] != string[(length - i - 1)]) {
            return False;
        }
    }
    return True;
}



with entry {
    print(is_palindrome('hello'));
    print(is_palindrome('level'));
}
