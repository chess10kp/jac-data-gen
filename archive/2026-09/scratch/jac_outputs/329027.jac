glob BYTE_MASK = 0x00000000000000ff;
glob UNPACK_MASK_1 = 0x0000000f0000000f;
glob UNPACK_MASK_2 = 0x0003000300030003;
glob UNPACK_MASK_3 = 0x0101010101010101;

"""Expand a bitfield into a 64-bit int (8 bool bytes)."""
def unpack_bits(byte: int) -> int {
    longbits = byte & BYTE_MASK;
    longbits = (longbits | (longbits << 28)) & UNPACK_MASK_1;
    longbits = (longbits | (longbits << 14)) & UNPACK_MASK_2;
    longbits = (longbits | (longbits << 7)) & UNPACK_MASK_3;
    return longbits;
}