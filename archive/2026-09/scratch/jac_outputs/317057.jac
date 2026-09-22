"""Snowfall accumulation calculation (STICS SnowAccumulation v1.0)."""
def model_snowaccumulation(
    tsmax: float = 0.0, tmax: float = 0.0, trmax: float = 0.0, precip: float = 0.0
) -> float {
    fs = 0.0;
    if tmax < tsmax {
        fs = 1.0;
    }
    if tmax >= tsmax and tmax <= trmax {
        fs = (trmax - tmax) / (trmax - tsmax);
    }
    return fs * precip;
}