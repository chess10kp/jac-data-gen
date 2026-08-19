def is_palindrome(s: Any) -> object {
    if (len(s) <= 1) {
        return True;
    }
    if (s[0].lower() != s[-1].lower()) {
        return False;
    }
    return is_palindrome(s[1:-1]);
}



with entry {
    print(is_palindrome('hello'));
    print(is_palindrome([]));
}
