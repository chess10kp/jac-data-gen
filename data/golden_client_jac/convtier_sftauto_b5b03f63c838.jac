def is_palindrome(s: Any) -> object {
    s = ''.join(filter(str.isalnum, s.lower()));
    return (s == s[::-1]);
}



with entry {
    print(is_palindrome('hello'));
    print(is_palindrome('Racecar'));
}
