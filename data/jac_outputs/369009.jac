"""Introduced by Feng et al. 2008."""
def chaotic_inertia_weight(
    c1: float,
    c2: float,
    z: float,
    max_iter: int,
    current_iter: int
) -> float {
    z = 4 * z * (1 - z);
    return (c1 - c2) * ((max_iter - current_iter) / max_iter) + c2 * z;
}