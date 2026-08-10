"""Returns the extinction coefficient for a given band."""
def get_ext_coeffs(band: str) -> float {
    exts = {"G": 3.214, "R": 2.165, "Z": 1.211, "W1": 0.184, "W2": 0.113};
    return exts[band];
}