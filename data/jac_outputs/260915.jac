"""Given rho and internal energy, return h."""
def h_from_eps(gamma: float, eint: float) -> float {
    1 + gamma * eint
}