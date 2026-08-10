glob BYTE_MASK = 255;

"""Generates a transitive color between first and second ones, based on the transition argument, where the value 0.0 is equivalent to the first color, and 1.0 is the second color."""
def transition(color1: int, color2: int, position: float) -> int {
    (r1, g1, b1) = (color1 >> 16, (color1 >> 8) & BYTE_MASK, color1 & BYTE_MASK);
    (r2, g2, b2) = (color2 >> 16, (color2 >> 8) & BYTE_MASK, color2 & BYTE_MASK);
    r = int(r1 + ((r2 - r1) * position) // 1) << 16;
    g = int(g1 + ((g2 - g1) * position) // 1) << 8;
    b = int(b1 + ((b2 - b1) * position) // 1);
    return r | g | b;
}