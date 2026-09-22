"""Count the number of zero bits on the right hand side."""
def _count_righthand_zero_bits(number: int, bits: int) -> int {
    if number == 0 {
        return bits;
    }
    return min(bits, (~number & (number - 1)).bit_length());
}