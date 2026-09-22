"""check composite number for rabin-miller primality test"""
def try_composite(a: int, d: int, n: int, s: int) -> bool {
    if pow(a, d, n) == 1 {
        return False;
    }
    for i in range(s) {
        if pow(a, (2 ** i) * d, n) == n - 1 {
            return False;
        }
    }
    return True;
}