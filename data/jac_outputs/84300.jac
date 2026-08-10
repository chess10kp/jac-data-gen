"""Compute the 2's complement of int value val."""
def twos_comp(val: int, bits: int) -> int {
    if val & (1 << (bits - 1)) != 0 {
        val = val - (1 << bits);
    }
    return val;
}