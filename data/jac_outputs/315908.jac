"""Limit a number within a specific range."""
def limit(min_: float, num: float, max_: float) -> float {
    return max(min(num, max_), min_);
}