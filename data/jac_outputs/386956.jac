glob BYTE_MASK = 0xFF;
glob HIGH_BYTE_MASK = 0xFF00;
glob UINT16_MASK = 0xFFFF;

"""
Pack unsigned short to network order unsigned short
"""
def pack_ushort_to_hn(val: int) -> int {
    return ((val & BYTE_MASK) << 8) | ((val & HIGH_BYTE_MASK) >> 8) & UINT16_MASK;
}