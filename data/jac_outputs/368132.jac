"""Modeled after the piecewise cubic
    y = (1/2)((2x)^3)       ; [0, 0.5)
    y = (1/2)((2x-2)^3 + 2) ; [0.5, 1]
    """
def cubic_ease_in_out(p: float) -> float {
    if p < 0.5 {
        return 4 * p * p * p;
    }
    f = 2 * p - 2;
    return 0.5 * f * f * f + 1;
}