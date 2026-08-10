"""Convert a value ranging from 0 to 100 into a color ranging from red to green using the HSL colorspace."""
def value_to_HSL(value: int) -> tuple[int, int, int] {
    hue = int(value * 1.2);
    saturation = 90;
    lightness = 40;
    return (hue, saturation, lightness);
}