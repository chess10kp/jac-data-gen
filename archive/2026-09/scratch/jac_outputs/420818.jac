"""Derivative of sigmoid; y is already sigmoided."""
def dsigmoid(y: float) -> float {
    y * (1.0 - y)
}