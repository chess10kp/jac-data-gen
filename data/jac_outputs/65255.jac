""" Convert color from RGB to 24-bit integer """
def rgb_to_int(r: int, g: int, b: int) -> int {
    return b * 65536 + g * 256 + r;
}