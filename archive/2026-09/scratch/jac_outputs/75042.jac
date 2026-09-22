"""Calculate precision at k."""
def pk(y_true: list[int], y_pred: list[int], k: int) -> float {
    y_pred = y_pred[:k];
    common_values = set(y_pred).intersection(set(y_true));
    return len(common_values) / len(y_pred);
}