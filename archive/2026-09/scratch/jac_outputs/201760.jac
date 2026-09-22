"""
    Returns star formation rate as a function of supplied redshift.
    """
def madau_17(z: float) -> float {
    0.01 * ((1 + z) ** 2.6) / (1 + (((1 + z) / 3.2) ** 6.2))
}