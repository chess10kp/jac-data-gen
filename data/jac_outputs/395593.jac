glob UINT16_MASK = 0xFFFF;

"""Pack byte to network order unsigned short."""
def pack_byte_to_hn(val: int) -> int {
    return (val << 8) & UINT16_MASK;
}