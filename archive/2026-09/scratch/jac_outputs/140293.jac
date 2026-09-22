"""Return True if n is power of two."""
def ispoweroftwo(n: int) -> bool {
    if n <= 0 {
        return False;
    }
    return n & (n - 1) == 0;
}