"""Convert timestamp to a pure floating point value.

None is encoded as inf.
"""
def _to_timestamp_float(timestamp: float | int | None) -> float {
    if timestamp is None {
        return float('inf');
    }
    return float(timestamp);
}