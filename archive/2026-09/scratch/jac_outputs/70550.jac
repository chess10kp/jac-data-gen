"""
    Good interpolator when you have two values to interpolate between, but doesn't give fluid animation
    when more points are involved since it follows straight lines between the points.
    """
def linearInterpolate(v1: Any, v2: Any, alpha: Any) -> object {
    return (v1 + (alpha * (v2 - v1)));
}