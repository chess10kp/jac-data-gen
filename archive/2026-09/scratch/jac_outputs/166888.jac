"""Convert gravity to degrees Plato."""
def gravity_to_deg_plato(sg: float) -> float {
    return 250.0 * (sg - 1.0);
}