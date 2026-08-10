"""Return a map of label counts for the given list of labels."""
def get_counts_per_label(y_true: list[int], n_classes: int) -> list[int] {
    label_counts = [0] * n_classes;
    for label in y_true {
        label_counts[label] += 1;
    }
    return label_counts;
}