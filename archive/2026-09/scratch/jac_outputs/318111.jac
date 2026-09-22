"""
    Given xs (in pb) and sum of gen weights,
    calculate scale1fb.
    """
def calc_scale1fb(xs: float, sum_weights: float) -> int | float {
    if xs <= 0 {
        return -1;
    }
    return (xs * 1000.0) / sum_weights;
}