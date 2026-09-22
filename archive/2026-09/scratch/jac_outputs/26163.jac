"""Calculate mean percentage error for fitted values to estimated values."""
def error(estimated: list[float], fitted: list[float]) -> float {
    sum([abs(e / f - 1) for (e, f) in zip(estimated, fitted)]) / len(estimated)
}