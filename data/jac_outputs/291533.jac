"""
    Convert axial coordinate to its cubic equivalent.
    """
def axial_to_cubic(col: int, slant: int) -> tuple[int, int, int] {
    x = col;
    z = slant;
    y = -x - z;
    return (x, y, z);
}