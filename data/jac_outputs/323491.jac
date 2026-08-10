glob UINT8_MASK = 0xFF;

"""Convert a 24 bit color to RGB triplets."""
def color_to_rgb(c: int) -> tuple[int, int, int] {
    return ((c >> 16) & UINT8_MASK, (c >> 8) & UINT8_MASK, c & UINT8_MASK);
}