"""Create a geometry of evenly-spaced hydrogen atoms along the Z-axis
    appropriate for consumption by MolecularData."""
def _h_n_linear_geometry(bond_distance: float, n_hydrogens: int) -> list[tuple[str, tuple[int, int, float]]] {
    return [('H', (0, 0, i * bond_distance)) for i in range(n_hydrogens)];
}