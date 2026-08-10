"""
Clauset et al 2007 equation 3.2:
    sigma = (alpha-1)/sqrt(n)
"""
def sigma(alpha: float, n: float) -> float {
    return (alpha - 1.0) / (n ** 0.5);
}