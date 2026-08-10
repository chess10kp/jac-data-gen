"""Return (red, green, blue) values from hexadecimal color code #rrggbb."""
def hex_to_rgb(value: str) -> tuple[float, float, float] {
    lv = len(value);
    out = tuple(int(value[i:(i + lv // 3)], 16) for i in range(0, lv, lv // 3));
    return tuple(x / 256.0 for x in out);
}