"""Return the bounding vertices of the texture square."""
def tex_coord(x: int | float, y: int | float, n: int | float = 8) -> tuple[float, float, float, float, float, float, float, float] {
    m = 1.0 / n;
    dx = x * m;
    dy = y * m;
    return (dx, dy, dx + m, dy, dx + m, dy + m, dx, dy + m);
}