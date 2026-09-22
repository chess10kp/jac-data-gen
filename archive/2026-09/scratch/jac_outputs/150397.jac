"""Computes the correct hcc value."""
def max_hcc_value(nelem: float, nlayers: float, slope: float) -> float {
    dx = 1.0 / nelem;
    dz = 1.0 / nlayers;
    return slope * dx / dz;
}