""" 3 vector, vector ''a'' times scalar ``c``, `a * c`"""
def scale3(a: list[float], c: float) -> list[float] {
    return [a[0] * c, a[1] * c, a[2] * c, 1.0];
}