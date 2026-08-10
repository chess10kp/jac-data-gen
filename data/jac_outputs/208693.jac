"""Convert a Scenic position to a Webots position."""
def scenicToWebotsPosition(pos: tuple[float, float], y: float = 0) -> list[float] {
    (x, z) = pos;
    return [x, y, -z];
}