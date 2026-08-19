def is_palindrome(s: Any) -> object {
    s = ''.join(
        c
        for c in s
        if c.isalnum()
    ).lower();
    return (s == s[::-1]);
}



with entry {
    print(is_palindrome('hello'));
    print(is_palindrome('Racecar'));
}
