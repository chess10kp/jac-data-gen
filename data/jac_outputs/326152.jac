"""Determine if a test result meets a particular threshold."""
def metric_passes(expected: float, got: float, tolerance: int) -> bool {
    if tolerance > 0 {
        expected = (1 - tolerance / 100) * expected;
    }
    got > expected
}