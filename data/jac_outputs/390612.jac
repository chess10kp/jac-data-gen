glob UINT64_MASK = 0xFFFFFFFFFFFFFFFF;

"""Packs an integer into a 8-byte string (big endian)"""
def p64b(x: int) -> bytes {
    import struct;
    return struct.pack('>Q', x & UINT64_MASK);
}