"""Inner product of two equal-length numeric vectors."""
def Dot(x: list[float], y: list[float]) -> float {
    sum(_x * _y for (_x, _y) in zip(x, y))
}