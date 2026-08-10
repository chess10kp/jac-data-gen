"""Returns the shortest value length found in matrix."""
def matrix_length(matrix: dict[str, list[object]]) -> int {
    return min(set(len(vals) for vals in matrix.values()));
}