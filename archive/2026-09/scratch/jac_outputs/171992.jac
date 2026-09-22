"""Translate a three dimensional grid point to a one dimensional index."""
def IJK(nx: int, ny: int, nz: int, i: int, j: int, k: int) -> int {
    return k * nx * ny + j * nx + i;
}