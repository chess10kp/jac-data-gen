"""Compute the union of the ground truth and predicted lists."""
def union(actual: list[str], predicted: list[str]) -> set[str] {
    return set(actual).union(set(predicted));
}