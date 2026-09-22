"""Strip outermost characters if same, return false when mismatch."""
def is_palindrome2(w: str) -> bool {
    while len(w) > 1 {
        if w[0] != w[-1] {
            return False;
        }
        w = w[1:-1];
    }
    return True;
}