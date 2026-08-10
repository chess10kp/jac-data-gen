"""Add two coordinates."""
def coords_add(coords0: tuple[int, ...], coords1: tuple[int, ...]) -> tuple[int, ...] {
    return tuple([(x0 + x1) for (x0, x1) in zip(coords0, coords1)]);
}