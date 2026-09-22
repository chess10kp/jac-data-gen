"""Gets the names of the metrics."""
def get_metrics_names(metrics: dict[str, dict[str, float]]) -> list[str] {
    if len(metrics) == 0 {
        return [];
    }
    metrics_dict = next(iter(metrics.values())) as dict[str, float];
    return list(metrics_dict.keys());
}