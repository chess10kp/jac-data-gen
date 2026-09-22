"""
    Checks if n is a prime number
    Returns: boolean (True if n is prime, False otherwise)
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
    for x in range(3, int(n ** 0.5) + 1, 2) {
        if n % x == 0 {
            return False;
        }
    }
    return True;
}