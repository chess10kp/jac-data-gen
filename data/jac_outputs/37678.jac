"""Count false negatives where true label is 1 and prediction is 0."""
def false_negative(y_true: list[int], y_pred: list[int]) -> int {
    return sum(1 for (yt, yp) in zip(y_true, y_pred) if yt == 1 and yp == 0);
}