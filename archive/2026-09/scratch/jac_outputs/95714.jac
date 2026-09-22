"""Polynomial transition from 0 to 1 with continuous first derivative."""
def smoothstep(x: float) -> float {
    -2 * x ** 3 + 3 * x ** 2
}