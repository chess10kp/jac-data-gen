"""Determine whether a word or phrase is a palindrome."""
def palindrome(value: str) -> bool {
    value = value.replace(" ", "").lower();
    return value == value[::-1];
}