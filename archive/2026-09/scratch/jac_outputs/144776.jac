"""Linear distance weighting."""
def dist2weights_linear(
    dist: float, max_r: float, max_w: int = 1, min_w: float = 0
) -> float {
    weights = (max_w - dist) * ((max_w - min_w) / float(max_r)) + min_w;
    return weights;
}