"""
A lorentz function that takes linewidth at half intensity (w) as a
parameter.

When `v` = `v0`, and `w` = 0.5 (Hz), the function returns intensity I.
"""
def lorentz(v: float, v0: float, I: float, w: float) -> float {
    scaling_factor = 0.5 / w;
    half_w = 0.5 * w;
    return scaling_factor * I * (half_w ** 2 / (half_w ** 2 + (v - v0) ** 2));
}