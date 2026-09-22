"""BBox serves for the plotting size figures."""
def create_bbox(boundries: list[float] | tuple[float, float, float, float]) -> tuple[float, float, float, float] {
    return (boundries[3], boundries[2], boundries[1], boundries[0]);
}