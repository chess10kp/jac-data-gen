def is_palindrome(s: Any) -> object {
    return (s == s[::-1]);
}



with entry {
    print(is_palindrome('hello'));
    print(is_palindrome('level'));
}
