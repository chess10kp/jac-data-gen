"""Normalizes the difference between actual and predicted values."""
def magnitude_relative_error(
    estimate: float, actual: float, balanced: bool = False
) -> float {
    if not balanced {
        denominator = actual;
    } else {
        denominator = min(estimate, actual);
    }
    if denominator == 0 {
        denominator = 1;
    }
    return float(abs(estimate - actual)) / float(denominator);
}