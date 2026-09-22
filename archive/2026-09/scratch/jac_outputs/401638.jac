glob UINT32_MASK = 0xFFFFFFFF;

"""Convert a prefix length to an IP mask integer."""
def pfxlen2mask_int(pfxlen: int) -> int {
    return UINT32_MASK << (32 - int(pfxlen));
}