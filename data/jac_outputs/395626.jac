"""Converts an array of labels into an array of label_ids."""
def _prepare_labels(labels: list[str], label_map: dict[str, int]) -> list[int] {
    return [label_map[label] for label in labels];
}