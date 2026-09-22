"""Return True if string is a palindrome, False otherwise.
        A palindrome is a string who can be read the same both
        ways.
    """
def is_a_palindrome(string: str) -> bool {
    string == ''.join(reversed(string))
}