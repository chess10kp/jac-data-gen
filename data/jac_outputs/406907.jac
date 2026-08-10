"""Calculate F1 score from parallel precision and recall sequences."""
def f1_score_prob(precision: list[float], recall: list[float]) -> list[float] {
    return [(2.0 * x * y) / (x + y) for (x, y) in zip(precision, recall)];
}