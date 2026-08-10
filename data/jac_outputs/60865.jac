"""convert a non-negative integer to raw binary buffer"""
def int2bin(n: int) -> bytes {
    buf = bytearray();
    while n > 0 {
        buf.insert(0, n & 255);
        n >>= 8;
    }
    return bytes(buf);
}