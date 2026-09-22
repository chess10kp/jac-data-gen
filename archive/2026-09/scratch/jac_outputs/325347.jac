"""Galois Field multiplication of a by b, modulo m.

    Just like arithmetic multiplication, except that additions and
    subtractions are replaced by XOR.
    """
def gf_mult(a: int, b: int, m: int) -> int {
    res = 0;
    while b != 0 {
        if b & 1 {
            res ^= a;
        }
        a <<= 1;
        b >>= 1;
        if a >= 256 {
            a ^= m;
        }
    }
    res
}