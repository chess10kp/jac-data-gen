"""
Returns the distance in kpc for a distance modulus.

dm (float): distance modulus.
absorption (float): absorption to the source.
"""
def Distance_modulus_to_distance(dm: float, absorption: float = 0.0) -> float {
    return (10.0 ** ((dm - absorption + 5.0) / 5.0)) / 1000.0;
}