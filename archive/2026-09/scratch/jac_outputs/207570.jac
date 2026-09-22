"""Accuracy score function."""
def accuracy(y_true: list[int], y_pred: list[int]) -> float {
    length = len(y_true);
    correct = 0;
    for i in range(length) {
        if y_true[i] == y_pred[i] {
            correct += 1;
        }
    }
    return float('{:.4f}'.format(correct / length));
}