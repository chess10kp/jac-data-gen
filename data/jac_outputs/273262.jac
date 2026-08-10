"""Check if the timestamps are strictly increasing.

Strictly increasing means values are increasing and 100ps apart."""
def is_strictly_increasing(timestamps: list[int] | None) -> bool {
    if timestamps is None or len(timestamps) == 0 {
        return True;
    }
    return all(x < y and x + 100 == y for (x, y) in zip(timestamps, timestamps[1:]));
}