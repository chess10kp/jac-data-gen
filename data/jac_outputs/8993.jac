"""Expects two bytes objects of equal length, returns their XOR."""
def xor(b1: bytes, b2: bytes) -> bytes {
    assert len(b1) == len(b2);
    return bytes([(x ^ y) for (x, y) in zip(b1, b2)]);
}