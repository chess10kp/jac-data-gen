"""Calculate the area under the curve minus the area below the starting OD."""
def calcShiftAUC(auc: float, y0: float, tF: float) -> float {
    return auc - y0 * tF;
}