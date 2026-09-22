""" Returns True if number is palindrome """
def palindrome(number: int | str) -> bool {
    s = str(number);
    for idx in range(len(s) // 2) {
        if s[idx] != s[len(s) - idx - 1] {
            return False;
        }
    }
    return True;
}