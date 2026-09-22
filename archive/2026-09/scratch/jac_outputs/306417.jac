"""Get the targets for the k nearest neighbors of a new sample,
    according to a distance metric.
    """
def nearest_neighbors_targets(
    x_train: list[list[float]], y_train: list[int], x_new: list[float], k: int, distance: Callable[[list[float], list[float]], float]
) -> list[int] {
    training_samples = list(zip(x_train, y_train));
    neighbors = sorted(
        ((x, y) for (x, y) in training_samples),
        key=lambda (sample: tuple[list[float], int]) { distance(x_new, sample[0]); }
    );
    return [target for (_, target) in neighbors[:k]];
}