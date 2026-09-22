"""Computes precision, recall and f1-score from count of TP, TN and FN."""
def _compute_metrics(tp: int, fp: int, fn: int) -> dict[str, float] {
    res: dict[str, float] = {};
    res['precision'] = tp / (tp + fp);
    res['recall'] = tp / (tp + fn);
    res['f1_score'] = (2 * res['precision'] * res['recall']) / (res['precision'] + res['recall']);
    return res;
}