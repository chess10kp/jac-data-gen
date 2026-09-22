"""Returns the flattened array of the vectors."""
def _flatten_vectors(vectors: list) -> list[float] {
    return sum(map(lambda (v) { [getattr(v, "x"), getattr(v, "y"), getattr(v, "z")]; }, vectors), []);
}