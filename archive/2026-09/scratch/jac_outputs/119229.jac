"""Calculate water vapor mixing ratio (1) from specific humidity q (1)."""
def calc_w_from_q(q: float) -> float {
    return q / (1.0 - q);
}