"""Infer the separation of a combined lens from the individual focal lengths and the effective focal length."""
def infer_combined_lens_separation(f1: float, f2: float, f: float) -> float {
    f1 + f2 - f1 * f2 / f
}