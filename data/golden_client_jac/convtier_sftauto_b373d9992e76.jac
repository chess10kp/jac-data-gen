def is_palindrome(s: Any) -> object {
    s = ''.join(
        e
        for e in s
        if e.isalnum()
    ).lower();
    return (s == s[::-1]);
}



with entry {
    print(is_palindrome('hello'));
    print(is_palindrome('Racecar'));
}
