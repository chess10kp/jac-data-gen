def is_palindrome(s: Any) -> object {
    s = ''.join(
        c.lower()
        for c in s
        if c.isalnum()
    );
    left = 0;
    right = len(s) - 1;
    while (left < right) {
        if (s[left] != s[right]) {
            return False;
        }
        left += 1;
        right -= 1;
    }
    return True;
}



with entry {
    print(is_palindrome('hello'));
    print(is_palindrome('Racecar'));
}
