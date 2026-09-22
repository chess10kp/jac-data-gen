"""Function for pandas.apply() that assigs values into bins"""
def _in_ranges(x: float, bins: list[tuple[float, float]]) -> list[bool] {
    return [((x >= lower) & (x <= upper)) for (lower, upper) in bins];
}