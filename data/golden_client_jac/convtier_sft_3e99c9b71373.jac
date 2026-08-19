def is_palindrome(s: str) -> bool {
    return s == s[::-1];
}

with entry {
    print(is_palindrome("racecar"));
    print(is_palindrome("hello"));
}
