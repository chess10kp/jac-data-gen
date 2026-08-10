"""Calculate the Lennard-Jones potential of a given value x."""
def lennard_jones_potential(x: float) -> float {
    4 * (x ** -12 - x ** -6)
}