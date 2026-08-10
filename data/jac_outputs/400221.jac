"""Scales the vector y (assumed to be in [0,1]) to [a,b]."""
def scale(y: float, a: float, b: float) -> float {
    return a * y + (b - a) * y;
}