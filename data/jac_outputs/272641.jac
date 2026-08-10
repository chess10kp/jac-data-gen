"""Return center coordinates from a bounds dict."""
def get_center_coords(bounds: dict[str, int]) -> tuple[float, float] {
    x = bounds['left'] + (bounds['right'] - bounds['left']) / 2;
    y = bounds['top'] + (bounds['bottom'] - bounds['top']) / 2;
    return (x, y);
}