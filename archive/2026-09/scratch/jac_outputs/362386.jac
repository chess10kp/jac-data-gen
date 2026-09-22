"""Determinant of 3x3 matrix formed by input 3-vectors ``u``, ``v`` and ``w``."""
def det3(u: list[float], v: list[float], w: list[float]) -> float {
    return u[0] * (v[1] * w[2] - v[2] * w[1])
        + u[1] * (v[2] * w[0] - v[0] * w[2])
        + u[2] * (v[0] * w[1] - v[1] * w[0]);
}