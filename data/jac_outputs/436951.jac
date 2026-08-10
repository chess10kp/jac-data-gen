"""
    Computes the size of the interval between points in a multiplot.
    """
def _multiplot_interval(from_date: float, to_date: float, points: int) -> float {
    if points < 2 {
        return 0.0;
    }
    return (to_date - from_date) / (points - 1);
}