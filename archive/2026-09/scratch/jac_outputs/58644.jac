"""Add offset to point.
            point: tuple(x, y, z)
            offset: tuple(x, y, z)
            return: tuple(x, y, z)
    """
def appro(point: tuple[int, int, int], offset: tuple[int, int, int]) -> tuple[int, int, int] {
    return tuple(p + o for (p, o) in zip(point, offset));
}