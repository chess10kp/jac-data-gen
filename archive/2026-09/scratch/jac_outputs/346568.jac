glob UINT32_MASK = 0xFFFFFFFF;

"""Fix negative integer values returned by TSK."""
def _FixInt(value: int) -> int {
    if value < 0 {
        value &= UINT32_MASK;
    }
    return value;
}