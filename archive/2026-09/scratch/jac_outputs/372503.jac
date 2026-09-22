"""Returns True if n is prime and False otherwise."""
def is_prime(n: int) -> bool {
    if n == 1 {
        return False;
    }
    for divider in range(2, int(n ** 0.5) + 1) {
        if n % divider == 0 {
            return False;
        }
    }
    return True;
}