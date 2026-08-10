"""Vertical uplift factor for sand."""
def Ncv(c: float, H: float, D: float) -> float {
    if c == 0 {
        return 0;
    }
    return min(2 * H / D, 10);
}