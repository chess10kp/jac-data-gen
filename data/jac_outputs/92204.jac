"""Affine map from interval [l0, h0] to [l1, h1].
    Broadcasting is used to match corresponding dimensions.
    """
def map_affine(x: float, l0: float, h0: float, l1: float = 0.0, h1: float = 1.0) -> float {
    return l1 + (x - l0) / (h0 - l0) * (h1 - l1);
}