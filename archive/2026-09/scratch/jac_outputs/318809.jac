"""Calculates the incremental mean different batch sizes."""
def incremental_mean_differentSizeBatches(
    xbarj: float, Nj: float, xbarm: float, Nm: float
) -> float {
    return (Nj * xbarj + Nm * xbarm) / (Nj + Nm);
}