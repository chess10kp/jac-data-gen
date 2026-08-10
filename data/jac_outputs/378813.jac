"""Returns the percentage change between the specified values."""
def _GetPercentageChange(value1: float, value2: float) -> float {
    difference = value2 - value1;
    return 0 if value1 == 0 else difference / value1 * 100;
}