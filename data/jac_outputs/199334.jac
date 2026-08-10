"""Clamp value to low or high as necessary."""
def _clamp(low: int | float, value: int | float, high: int | float) -> int | float {
    result = value if value >= low else low;
    result = value if value <= high else high;
    return result;
}