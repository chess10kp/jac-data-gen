"""Compute enhanced vegetation index"""
def evi_func(blue: float, red: float, nir: float) -> float {
    return (2.5 * (nir - red)) / ((nir + (6 * red)) - (7.5 * blue) + 1);
}