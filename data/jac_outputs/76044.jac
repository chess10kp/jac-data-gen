"""Clip a value to the given range."""
def clip(value: float, min_value: float, max_value: float) -> float {
    if value < min_value {
        return min_value;
    }
    if value > max_value {
        return max_value;
    }
    return value;
}