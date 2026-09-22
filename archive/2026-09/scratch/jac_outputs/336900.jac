"""Slow trial division primality testing algorithm (Always correct)."""
def is_prime_slow(n: int) -> bool {
    if n <= 1 {
        return False;
    }
    x = 2;
    while x * x <= n {
        if n % x == 0 {
            return False;
        }
        x += 1;
    }
    return True;
}