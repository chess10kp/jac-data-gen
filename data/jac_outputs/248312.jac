"""Reports the confusion-matrix label for a dataframe row."""
def create_confusion_matrix(row: dict[str, int]) -> str {
    match (row['actual_label'], row['predicted_label']) {
        case (1, 1):
            return 'TP';
        case (1, _):
            return 'FN';
        case (_, 1):
            return 'FP';
        case _:
            return 'TN';
    }
}