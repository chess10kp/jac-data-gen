"""component-wise 3 vector multiplication"""
def mul(a: list[float], b: list[float]) -> list[float] {
    return [a[0] * b[0], a[1] * b[1], a[2] * b[2], 1.0];
}