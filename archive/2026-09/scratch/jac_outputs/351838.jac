"""Return whether integer x reads the same forwards and backwards."""
def isPalindrome(x: int) -> bool {
    if x < 0 {
        return False;
    }
    y = str(x);
    l = len(y);
    for i in range(l // 2) {
        if y[i] != y[l - i - 1] {
            return False;
        }
    }
    return True;
}