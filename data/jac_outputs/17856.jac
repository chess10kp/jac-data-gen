"""Return `size` bytes with a pattern of incrementing byte values."""
def incrementing_pattern(size: int) -> bytes {
    ret = bytearray(size);
    for i in range(0, size) {
        ret[i] = i & 255;
    }
    return bytes(ret);
}