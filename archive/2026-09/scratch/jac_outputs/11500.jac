"""Return the sensitivity based on the confusion matrix values."""
def calculateSensitivity(tn: int, fp: int, fn: int, tp: int) -> float {
    return tp / (tp + fn);
}