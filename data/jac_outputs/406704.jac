glob UINT32_MOD = 0x100000000;
glob BYTE_MASK = 0xFF;

"""Convert from a single ARGB value to a tuple containing RGBA."""
def _ArgbToRgbaTuple(argb: int) -> tuple[int, int, int, int] {
    unsigned_argb = argb % UINT32_MOD;
    return (
        (unsigned_argb >> 16) & BYTE_MASK,
        (unsigned_argb >> 8) & BYTE_MASK,
        unsigned_argb & BYTE_MASK,
        (unsigned_argb >> 24) & BYTE_MASK
    );
}