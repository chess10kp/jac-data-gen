"""RGB to HEX conversion"""
def rgb_to_hex(rgb: tuple[int, int, int]) -> str {
    '#%02x%02x%02x' % (rgb[0], rgb[1], rgb[2])
}