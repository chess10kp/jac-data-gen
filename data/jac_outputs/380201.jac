"""
Calculate list of precision and recall values from lists of true pos.,
false pos., false neg. values.
"""
def calculate_precision_recall(
    tp_totals: list[int], fp_totals: list[int], fn_totals: list[int]
) -> tuple[list[float], list[float]] {
    precision = [
        tp / (tp + fp) if tp + fp > 0 else 0
        for (tp, fp) in zip(tp_totals, fp_totals)
    ];
    recall = [
        tp / (tp + fn) if tp + fn > 0 else 0
        for (tp, fn) in zip(tp_totals, fn_totals)
    ];
    return (precision, recall);
}