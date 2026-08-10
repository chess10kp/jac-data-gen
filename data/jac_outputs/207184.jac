"""Gets a 3-tuple of RGB ints and return a 3-tuple of unity floats"""
def normalize_color(color: tuple[int, int, int]) -> tuple[float, float, float] {
    return (color[0] / 255.0, color[1] / 255.0, color[2] / 255.0);
}