"""Returns value of specified quantile of X."""
def quantile(x: list[int | float] | tuple[int | float, ...], percentile: float) -> int | float {
    if x {
        p_idx = int(percentile * len(x));
        return sorted(x)[p_idx];
    } else {
        raise ValueError('len of x == 0');
    }
}