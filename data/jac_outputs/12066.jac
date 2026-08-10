"""Estimate mean daily temperature from the daily minimum and maximum temperatures."""
def daily_mean_t(tmin: float, tmax: float) -> float {
    return (tmax + tmin) / 2.0;
}