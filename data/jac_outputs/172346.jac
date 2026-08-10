"""Return a xor b."""
def xor(a: bytes, b: bytes) -> bytes {
    assert len(a) == len(b), "Arguments must have same length.";
    (a, b) = (bytearray(a), bytearray(b));
    return bytes([a[i] ^ b[i] for i in range(len(a))]);
}