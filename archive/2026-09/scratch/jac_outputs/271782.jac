"""Calculates the bending rigidity of a plate."""
def rigidity_bending_plate(height: float, e_modulus: float, poisson: float) -> float {
    return e_modulus * height ** 3 / (12 * (1 - poisson ** 2));
}