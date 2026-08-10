"""Calculate the D-efficiency bound of an array extension."""
def DefficiencyBound(D: float, k: int, k2: int) -> float {
    m = 1.0 + k + (k * (k - 1)) / 2;
    m2 = 1.0 + k2 + (k2 * (k2 - 1)) / 2;
    return D ** (m / m2);
}