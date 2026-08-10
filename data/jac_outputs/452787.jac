"""Least significant bit of a number; num AND -num = LSB."""
def least_significan_bit(n: int) -> int | None {
    if (`type(n) != int) {
        raise TypeError("Number must be Integer.");
    }
    if n > 0 {
        return n & -n;
    }
}