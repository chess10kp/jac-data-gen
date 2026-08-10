"""Calculates the vector cross product of two 3D vectors, v1 and v2"""
def cross3D(v1: list[float], v2: list[float]) -> tuple[float, float, float] {
    (
        v1[1] * v2[2] - v1[2] * v2[1],
        v1[2] * v2[0] - v1[0] * v2[2],
        v1[0] * v2[1] - v1[1] * v2[0]
    )
}