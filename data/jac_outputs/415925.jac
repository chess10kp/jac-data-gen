"""Return the number of instances of a target class."""
def get_object_instances(
    predictions: list[dict[str, str | float]],
    target: str,
    confidence: float
) -> int {
    targets_identified = [
        pred
        for pred in predictions
        if pred['label'] == target and float(pred['confidence']) >= confidence
    ];
    return len(targets_identified);
}