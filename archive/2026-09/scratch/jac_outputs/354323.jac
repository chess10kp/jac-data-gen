"""Flips bit value at position pos from the left of the length-N bit-representation of n"""
def BitFlip(n: int, N: int, pos: int) -> int {
    n ^ (1 << (N - 1 - pos))
}