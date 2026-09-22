"""
    Check for the presence of the given letter in given word. Return True if none, else
    return False.
    word = word to check
    x = letter to check for
    """
def has_no_e(word: str, x: str) -> bool {
    for char in word[:] {
        if char == x {
            return False;
        }
    }
    return True;
}