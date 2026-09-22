"""
HSW (Hamaus-Sutter-Wendelt) function for the universal void density profile
See: Hamaus et al. (2014)
"""
def HSW_offset(
    r: float, rs: float, alpha: float, Rv: float, beta: float, deltac: float, offset: float
) -> float {
    numerator = 1 - (r / rs) ** alpha;
    denominator = 1 + (r / Rv) ** beta;
    return deltac * numerator / denominator + offset;
}