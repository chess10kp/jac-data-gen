"""Computes the next material index with respect to default avatar skin indices.

    Args:
        mtl (int): The current material index.

    Returns:
        int: The next material index to be used.
    """
def skip_material(mtl: int) -> int {
    if mtl in (1, 6) {
        return mtl + 2;
    }
    return mtl + 1;
}