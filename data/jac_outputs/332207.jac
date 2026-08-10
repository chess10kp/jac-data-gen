"""Set bit to at the given offset to 1."""
def set_bit(num: int, offset: int) -> int {
    mask = 1 << offset;
    return num | mask;
}