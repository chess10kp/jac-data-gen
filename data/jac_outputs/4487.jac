"""
    Adds two 3d vectors.
    v1, v2 (3-tuple): 3d vectors
    return (3-tuple): 3d vector
    """
def vect3_add(v1: tuple[float, float, float], v2: tuple[float, float, float]) -> tuple[float, float, float] {
    return (v1[0] + v2[0], v1[1] + v2[1], v1[2] + v2[2]);
}