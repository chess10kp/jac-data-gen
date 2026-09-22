"""
    k, a positive integer
    returns True if k is triangular and False if not
    """
def is_triangular(k: int) -> bool {
    it = 1;
    sum = 0;
    while sum <= k {
        if sum != k {
            sum = sum + it;
            it += 1;
        } else {
            return True;
        }
    }
    return False;
}