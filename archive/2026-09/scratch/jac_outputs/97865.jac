"""Convert degrees Plato to specific gravity."""
def deg_plato_to_gravity(deg_plato: float) -> float {
    return 1.0 + deg_plato / 250.0;
}