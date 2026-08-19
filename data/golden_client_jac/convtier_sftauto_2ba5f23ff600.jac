def is_palindrome(s: Any) -> object {
    s = ''.join(
        char.lower()
        for char in s
        if char.isalpha()
    );
    return (s == s[::-1]);
}



with entry {
    print(is_palindrome('hello'));
    print(is_palindrome('Racecar'));
}
