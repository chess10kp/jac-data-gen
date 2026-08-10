"""
Translates an rgb tuple of ints to a tkinter friendly color code
"""
def tkcolour_from_rgb(rgb: tuple[int, int, int]) -> str {
    return "#%02x%02x%02x" % rgb;
}