"""Return the least significant bit."""
def least_significant_bit(val: int) -> int {
    return (val & -val).bit_length() - 1;
}