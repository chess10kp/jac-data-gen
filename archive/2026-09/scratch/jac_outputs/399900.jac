""" helper method to calculate the relative error """
def _relative_error(
    expected_min: float | int, expected_max: float | int, actual: float | int
) -> float {
    if expected_min < 0 or expected_max < 0 or actual < 0 {
        raise Exception();
    }
    if expected_min <= actual and actual <= expected_max {
        return 0.0;
    }
    if expected_min == 0 and expected_max == 0 {
        return 0.0 if actual == 0 else float("+inf");
    }
    if actual < expected_min {
        return (expected_min - actual) / expected_min;
    }
    return (actual - expected_max) / expected_max;
}