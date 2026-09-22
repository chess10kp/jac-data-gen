"""x is a positive integer. Convert it to base two as a list of integers
    in reverse order as a list."""
def int2baseTwo(x: int) -> list[int] {
    assert x >= 0;
    bit_inverse = [];
    while x != 0 {
        bit_inverse.append(x & 1);
        x >>= 1;
    }
    return bit_inverse;
}