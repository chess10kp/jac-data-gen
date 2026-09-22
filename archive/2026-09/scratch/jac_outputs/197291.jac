"""Increase a input integer to be a multiple of mase_multiplier."""
def adjust_axial_sz_px(n: int, base_multiplier: int = 16) -> int {
    remainder = n % base_multiplier;
    if remainder == 0 { return n; }
    return n + base_multiplier - remainder;
}