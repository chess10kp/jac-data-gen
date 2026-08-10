"""Celsius to Fahrenheit."""
def c2f(c: float, r: int = 2) -> float {
    round(c * 1.8 + 32, r)
}