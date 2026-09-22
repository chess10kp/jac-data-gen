"""Modeled after the cubic y = (x - 1)^3 + 1."""
def cubic_ease_out(p: float) -> float {
    f = p - 1;
    return f * f * f + 1;
}