"""Compute the dot product between the two vectors a and b."""
def dot(a: list[float], b: list[float]) -> float {
    sum(i * j for (i, j) in zip(a, b))
}