"""
    Convert rmin/epsilon representation to AB representation of the LJ
    potential
    """
def _LJ_rminepsilon_to_ab(coeffs: Any) -> object {
    A = coeffs['epsilon'] * (coeffs['Rmin'] ** 12.0);
    B = 2 * coeffs['epsilon'] * (coeffs['Rmin'] ** 6.0);
    return {"A": A, "B": B};
}