"""Converts a integer color value to a RGB tuple."""
def IntToRgb(RGBint: int) -> tuple[int, int, int] {
    blue = RGBint & 255;
    green = (RGBint >> 8) & 255;
    red = (RGBint >> 16) & 255;
    return (red, green, blue);
}