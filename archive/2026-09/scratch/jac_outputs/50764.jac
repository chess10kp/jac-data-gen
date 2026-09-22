"""
    Time complexity: O(1).
    Space complexity: O(1).
    """
def consecutive_ducks2(n: int) -> bool {
    if n == 2 {
        return False;
    }
    if n % 2 == 1 {
        return True;
    }
    if n & (n - 1) == 0 {
        return False;
    }
    return True;
}