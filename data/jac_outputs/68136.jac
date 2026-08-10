"""Return exclusive or of two given byte arrays."""
def _xor(bs1: bytes, bs2: bytes, n: int) -> bytearray {
    bs = bytearray();
    for (b1, b2) in zip(bs1, bs2) {
        bs.append(b1 ^ b2);
    }
    return bs;
}