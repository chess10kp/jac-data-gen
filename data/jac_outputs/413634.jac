"""Convenience method to convert pymunk coordinates to px8."""
def to_px8(p: tuple[float, float]) -> tuple[int, int] {
    return (int(p[0]), 128 - int(p[1]));
}