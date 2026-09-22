"""Compare predicted and label set groups; return num_correct, num_pred, num_label."""
def sets_compare(sets_predict: list[list[tuple]], sets_label: list[list[tuple]]) -> tuple[int, int, int] {
    num_correct = 0;
    num_pred = 0;
    num_label = 0;
    for (pred, label) in zip(sets_predict, sets_label) {
        pred_set = set(pred);
        label_set = set(label);
        num_pred += len(pred_set);
        num_label += len(label_set);
        num_correct += len(pred_set & label_set);
    }
    return (num_correct, num_pred, num_label);
}