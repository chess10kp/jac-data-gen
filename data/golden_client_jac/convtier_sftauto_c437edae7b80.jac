def is_palindrome(s: Any) -> object {
    s = ''.join(
        e
        for e in s
        if e.isalnum()
    );
    s = s.lower();
    return (s == s[::-1]);
}



with entry {
    print(is_palindrome('hello'));
    print(is_palindrome('Racecar'));
}
