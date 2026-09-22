"""
    Returns bool of whether test is a palindrome.
    Does so iteratively
    """
def is_pal(`test: str) -> bool {
    reverse_test = `test[::-1];
    for i in range(len(`test)) {
        if `test[i] != reverse_test[i] {
            return False;
        }
    }
    return True;
}