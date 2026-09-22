"""Homogenise a list of vectors."""
def homogenize(xyz: list[tuple[float, float, float]], w: float = 1.0) -> list[list[float]] {
    return [
        [x * w, y * w, z * w, w] if w else [x, y, z, 0.0] for (x, y, z) in xyz
    ];
}