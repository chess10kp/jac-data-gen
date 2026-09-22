""" Create a new object each time the function is called, by using a default arg to signal that no argument was provided
        Do not use metrics = [] as it does not Create a new list each time the function is called instead it append to the list
        generated at the first call """
def get_sum_metrics(predictions: int, metrics: list[Callable[[int], int]] | None = None) -> int {
    if metrics is None {
        metrics = [];
    }
    for i in range(3) {
        metrics.append(lambda (x: int, i: int = i) { x + i });
    }
    sum_metrics = 0;
    for metric in metrics {
        sum_metrics += metric(predictions);
    }
    metrics = [];
    return sum_metrics;
}