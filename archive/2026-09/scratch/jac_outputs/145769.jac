"""Evaluate the performance of fuzzy joins."""
def evaluate(pred_joins: list[tuple[int, int]], gt_joins: list[tuple[int, int]]) -> tuple[float, float, float] {
    pred = {(l, r) for (l, r) in pred_joins};
    gt = {(l, r) for (l, r) in gt_joins};
    tp = pred.intersection(gt);
    precision = len(tp) / len(pred);
    recall = len(tp) / len(gt);
    f1 = 2 * precision * recall / (precision + recall);
    return (precision, recall, f1);
}