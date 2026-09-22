"""palindrome (string) - returns a boolean value for whether the parameter string is a palindrome"""
def palindrome(string: Any) -> object {
    if (str(string) == str(string)[::-1]) {
        return True;
    } else {
        return False;
    }
}