"""Given a set of (predictions, truth labels), return the accuracy of the predictions."""
def accuracy_score(data: list[tuple[int | str | float | bool, int | str | float | bool]]) -> float {
    return 100 * sum(1 if p == t else 0 for (p, t) in data) / len(data);
}