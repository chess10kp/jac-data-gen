"""Computes the Exact score (accuracy) of the predictions.

Exact score is defined as the percentage of predictions that match at least
one of the targets.
"""
def compute_exact_score(predictions: list[str], target_lists: list[list[str]]) -> float {
    num_matches = sum(
        any(pred == target for target in targets)
        for (pred, targets) in zip(predictions, target_lists)
    );
    return num_matches / max(float(len(predictions)), 0.1);
}