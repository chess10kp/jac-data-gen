"""Convert SRGB gamma corrected component to linear"""
def true_s2l(value: float) -> float {
    if value <= 0.04045 {
        return value / 12.92;
    }
    return ((value + 0.055) / 1.055) ** 2.4;
}