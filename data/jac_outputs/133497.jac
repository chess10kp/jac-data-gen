"""
Return True if the given integer is prime, False otherwise.
"""
def is_prime(n: int) -> bool {
    if n < 2 {
        return False;
    }
    if n == 2 {
        return True;
    }
    if n % 2 == 0 {
        return False;
    }
    for i in range(3, n) {
        if n % i == 0 {
            return False;
        }
    }
    return True;
}