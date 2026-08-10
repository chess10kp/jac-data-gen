"""Calculates 1D size of bounding box."""
def box_size_calculate(r: list[float]) -> tuple[float, float] {
    length = r[2] - r[0];
    width = r[3] - r[1];
    return (length, width);
}