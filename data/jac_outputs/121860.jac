"""Checks if the string representation of i has a palindrome."""
def has_palindrome(i: int, start: int, length: int) -> bool {
    s = str(i)[start:(start + length)];
    return s[::-1] == s;
}