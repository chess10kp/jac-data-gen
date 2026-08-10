"""A Loss function for duration costs."""
def duration_cost(y: float, y_pred: float) -> float {
    return (y - y_pred) ** 2;
}