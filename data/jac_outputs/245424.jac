"""Convert percentage to absolute value 0..255."""
def brightness_from_percentage(percent: int | float) -> float {
    return percent * 255.0 / 100.0;
}