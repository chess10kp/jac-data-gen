"""Returns a matrix indicating which pairs are good according to the given threshold."""
def threshold_matrix(threshold: float, score_matrix: list[list[float]]) -> list[list[int]] {
    return [[1 if score >= threshold else 0 for score in row] for row in score_matrix];
}