"""Clamp value between min_val and max_val."""
def clamp(x: float, min_val: float, max_val: float) -> float {
    return max(min(x, max_val), min_val);
}