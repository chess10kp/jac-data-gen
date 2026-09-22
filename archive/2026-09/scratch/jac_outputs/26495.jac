glob UINT32_MASK = 0xFFFFFFFF;

"""return the bit parity of the word 'x'."""
def bitparity(x: int) -> int {
    assert x >= 0, "bitparity(x) requires integer x >= 0";
    while x > UINT32_MASK {
        x = (x >> 32) ^ (x & UINT32_MASK);
    }
    x ^= x >> 16;
    x ^= x >> 8;
    x ^= x >> 4;
    return (27030 >> (x & 15)) & 1;
}