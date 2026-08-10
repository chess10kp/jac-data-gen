"""Compute contrast ratio of two luminance values."""
def get_cr_lum(lum1: float, lum2: float) -> float {
    val = (lum1 + 0.05) / (lum2 + 0.05);
    return val if val >= 1 else 1 / val;
}