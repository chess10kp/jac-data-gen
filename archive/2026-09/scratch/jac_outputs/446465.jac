"""Symmetrically extend the range given by the `min_max` pair.
   The new range will be 1 + `extend_ratio` larger than the original range.
"""
def extend_range(min_max: tuple[float, float], extend_ratio: float = 0.2) -> tuple[float, float] {
    mme = (min_max[1] - min_max[0]) * extend_ratio / 2;
    return (min_max[0] - mme, min_max[1] + mme);
}