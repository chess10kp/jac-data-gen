"""m*wavelength = neff * delta_length."""
def get_mzi_delta_length(m: float, neff: float = 2.4, wavelength: float = 1.55) -> float {
    return m * wavelength / neff;
}