"""rgb to 8-color pallete."""
def encode_color(rgb: list[int]) -> int | None {
    r = "1" if rgb[0] > 127 else "0";
    g = "1" if rgb[1] > 127 else "0";
    b = "1" if rgb[2] > 127 else "0";
    for i in range(8) {
        if r + g + b == format(i, '03b') {
            return i;
        }
    }
}