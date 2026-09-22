"""Put a newline on "::" for metric names."""
def _wrap_metric(metric_name: str) -> str {
    if "::" in metric_name {
        return "<br>".join(metric_name.split("::"));
    }
    return metric_name;
}