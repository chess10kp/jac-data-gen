"""Rescale 0 =< output =< 1."""
def scale_down(threshold: int | float, dim: int | float) -> float {
    return float(dim / threshold) if threshold else 0.0;
}