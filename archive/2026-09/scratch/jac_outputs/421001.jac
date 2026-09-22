"""Make a xor by bytes"""
def xor_bytes(bts1: bytes, bts2: bytes) -> bytes {
    return bytes([byte1 ^ byte2 for (byte1, byte2) in zip(bts1, bts2)]);
}