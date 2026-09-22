"""Unformat a single metric for the log_event API."""
def unformat_metric(metric: dict[str, str | int | float | list[dict[str, str]] | dict[str, str | int | float]]) -> dict[str, str | int | float | list[dict[str, str]] | dict[str, str | int | float]] {
    metric_keys = metric.keys();
    metric["metric_name"] = metric.pop("MetricName");
    if "Dimensions" in metric_keys {
        for dimension in metric["Dimensions"] as list[dict[str, str]] {
            dimension["name"] = dimension.pop("Name");
            dimension["value"] = dimension.pop("Value");
        }
        metric["dimensions"] = metric.pop("Dimensions");
    }
    if "Timestamp" in metric_keys {
        metric["timestamp"] = metric.pop("Timestamp");
    }
    if "Value" in metric_keys {
        metric["value"] = metric.pop("Value");
    } else {
        stats = metric["StatisticValues"] as dict[str, str | int | float];
        stats["sample_count"] = stats.pop("SampleCount");
        stats["sum"] = stats.pop("Sum");
        stats["minimum"] = stats.pop("Minimum");
        stats["maximum"] = stats.pop("Maximum");
        metric["statistic_values"] = metric.pop("StatisticValues");
    }
    if "Unit" in metric_keys {
        metric["unit"] = metric.pop("Unit");
    }
    if "StorageResolution" in metric_keys {
        metric["storage_resolution"] = metric.pop("StorageResolution");
    }
    return metric;
}