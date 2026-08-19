def is_palindrome(s: Any) -> object {
    s = ''.join(
        ch.lower()
        for ch in s
        if ch.isalnum()
    );
    s = s.strip();
    for i in range((len(s) // 2)) {
        if (s[i] != s[(len(s) - i - 1)]) {
            return False;
        }
    }
    return True;
}



with entry {
    print(is_palindrome('hello'));
    print(is_palindrome('Racecar'));
}
