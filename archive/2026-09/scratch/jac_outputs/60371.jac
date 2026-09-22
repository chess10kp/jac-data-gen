"""
    Does a left binary circular shift on the number x of n_bits bits
    """
def left_circ_shift(x: int, shift: int, n_bits: int) -> int {
    mask = (1 << n_bits) - 1;
    x_base = x << shift & mask;
    return x_base | x >> (n_bits - shift);
}