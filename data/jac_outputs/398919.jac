"""Get minimum and maximum tolerance range."""
def get_tolerance_min_max(value: int | float | str, expected_tolerance: int) -> tuple[float, float] {
    value = int(value);
    tolerance = (value * expected_tolerance) / 100;
    min_value = abs(value - tolerance);
    max_value = abs(value + tolerance);
    return (min_value, max_value);
}