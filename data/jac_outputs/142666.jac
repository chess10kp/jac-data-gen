"""Returns whether a number is palindromic."""
def isPalindrome(n: int) -> bool {
    s = str(n);
    return s == s[::-1];
}