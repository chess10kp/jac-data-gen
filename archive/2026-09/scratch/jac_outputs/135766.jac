"""Bitwise NOT in Python for n bits by default."""
def not_lane(b: int, n: int) -> int {
    return (1 << n) - 1 - b;
}