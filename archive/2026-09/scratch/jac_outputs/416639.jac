"""Isolate the rightmost 0-bit."""
def isolate_rightmost_0_bit(n: int) -> int {
    return ~n & (n + 1);
}