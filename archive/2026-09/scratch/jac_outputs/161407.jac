"""Matthew correlation coefficient between observed and predicted classifications."""
def Matthew_Correlation_Coefficient(TP: int, TN: int, FP: int, FN: int) -> float | None {
    num = (TP * TN) - (FP * FN);
    denom = ((TP + FP) * (TP + FN) * (TN + FP) * (TN + FN)) ** 0.5;
    if denom != 0 {
        return num / denom;
    }
    return None;
}