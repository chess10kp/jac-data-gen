"""Computes a contingency table for given predictions.

    >>> ys =    [True, True, True, True, True, False]
    >>> yhats = [True, True, False, False, False, True]
    >>> tab = contingency_table(ys, yhats, 1)
    >>> print(tab)
    (2, 1, 0, 3)

    """
def contingency_table(ys: list[bool | int], yhats: list[bool | int], positive: bool | int = True) -> tuple[int, int, int, int] {
    TP = 0;
    TN = 0;
    FP = 0;
    FN = 0;
    for (y, yhat) in zip(ys, yhats) {
        if y == positive {
            if y == yhat {
                TP += 1;
            } else {
                FN += 1;
            }
        } elif y == yhat {
            TN += 1;
        } else {
            FP += 1;
        }
    }
    return (TP, FP, TN, FN);
}