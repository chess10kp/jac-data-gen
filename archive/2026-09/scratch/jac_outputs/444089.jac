"""Get the n-best logits from a list."""
def _get_best_indexes(logits: list[float], n_best_size: int) -> list[int] {
    index_and_score: list[tuple[int, float]] = sorted(
        enumerate(logits), key=lambda (x: tuple[int, float]) { x[1]; }, reverse=True
    );
    best_indexes = [];
    for i in range(len(index_and_score)) {
        if i >= n_best_size {
            break;
        }
        best_indexes.append(index_and_score[i][0]);
    }
    return best_indexes;
}