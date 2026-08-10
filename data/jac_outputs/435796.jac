"""Unsigned Bitfield Extract."""
def ubfx(value: int, lsb: int, width: int) -> int {
    return (value >> lsb) & ((1 << width) - 1);
}