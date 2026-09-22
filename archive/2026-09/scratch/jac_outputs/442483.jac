"""Cast an int to a byte value."""
def to_byte(val: int) -> bytes {
    return val.to_bytes(1, 'little');
}