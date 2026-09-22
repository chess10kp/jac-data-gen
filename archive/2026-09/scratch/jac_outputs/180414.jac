"""Calculates the inverse of input decibel values."""
def idecibel(x: float) -> float {
    10.0 ** (x / 10.0)
}