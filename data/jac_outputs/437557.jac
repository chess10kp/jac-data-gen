"""Convert millisecond Epoch timestamp to Python float time value."""
def time_at_timestamp(timestamp_ms: int) -> float {
    return float(timestamp_ms) / 1000.0;
}