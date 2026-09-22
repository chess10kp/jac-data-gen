"""Stagnation density / static density ratio."""
def stag_density_ratio(M: float, gamma: float) -> float {
    return (1 + (gamma - 1) / 2 * M ** 2) ** (1 / (gamma - 1));
}