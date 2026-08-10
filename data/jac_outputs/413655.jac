""" Returns the ROC curve as an iterator of (x, y)-points,
        for the given list of (TP, TN, FP, FN)-tuples.
        The x-axis represents FPR = the false positive rate (1 - specificity).
        The y-axis represents TPR = the true positive rate.
    """
def roc(tests: list[tuple[int, int, int, int]] = []) -> list[tuple[float, float]] {
    x = FPR=lambda (TP: int, TN: int, FP: int, FN: int) { float(FP) / ((FP + TN) or 1); };
    y = TPR=lambda (TP: int, TN: int, FP: int, FN: int) { float(TP) / ((TP + FN) or 1); };
    return sorted([(0.0, 0.0), (1.0, 1.0)] + [(x(*m), y(*m)) for m in tests]);
}