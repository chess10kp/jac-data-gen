"""Compute word level Jaccard similarity."""
def jaccard_word_level_similarity(y_true: str, y_pred: str) -> float {
    true_set = set(y_true.lower().split());
    pred_set = set(y_pred.lower().split());
    y_intersect = true_set.intersection(pred_set);
    return len(y_intersect) / (len(true_set) + len(pred_set) - len(y_intersect));
}