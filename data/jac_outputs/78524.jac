"""Subtract two 3-element vectors."""
def vector_sub(vector1: list[float], vector2: list[float]) -> list[float] {
    return [
        vector1[0] - vector2[0],
        vector1[1] - vector2[1],
        vector1[2] - vector2[2]
    ];
}