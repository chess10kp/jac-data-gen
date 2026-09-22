"""Encode an 8-bit unsigned integer."""
def u8(x: int) -> bytes {
    assert 0 <= x < 256;
    return x.to_bytes(1, byteorder='little');
}