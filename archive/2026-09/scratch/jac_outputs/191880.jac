"""
    fitting function according to the common two site model. In general, x represents the pO2 or pCO2 content, whereas
    m, k and f are the common fitting parameters
    """
def _simplifiedSV(x: float, f: float, k: float) -> float {
    1 / (f / (1.0 + k * x) + (1.0 - f))
}