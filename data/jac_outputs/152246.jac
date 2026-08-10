"""Precision or positive predictive value"""
def precision(TP: int, FP: int) -> float {
    return TP / (TP + FP);
}