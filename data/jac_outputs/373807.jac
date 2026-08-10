"""Dot product of two equal-dimensioned vectors."""
def dotp(a: list[float], b: list[float]) -> float {
    sum(aterm * bterm for (aterm, bterm) in zip(a, b))
}