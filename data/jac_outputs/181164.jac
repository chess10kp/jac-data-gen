"""Calculate the average of the last three datapoints in the series."""
def _tail_avg(timeseries: list[list[float]], tidx: int = 0, vidx: int = 1) -> float {
    try {
        t = (timeseries[-1][vidx] + timeseries[-2][vidx] + timeseries[-3][vidx]) / 3;
        return t;
    } except IndexError {
        return timeseries[-1][vidx];
    }
}