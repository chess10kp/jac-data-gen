"""Convert red, green and blue values (0-255) into a 16-bit 565 encoding."""
def color565(r: int | tuple[int, int, int] | list[int], g: int = 0, b: int = 0) -> int {
    try {
        (r, g, b) = r;
    } except TypeError {
        ;
    }
    return (r & 248) << 8 | (g & 252) << 3 | b >> 3;
}