"""
    Returns the equation of a line in the form mx+b as a tuple of (m, b) for two points.
    Does not check for vertical lines.
    """
def get_eqn(p0: Any, p1: Any) -> object {
    m = (p0[1] - p1[1]) / (p0[0] - p1[0]);
    return (m, (p0[1] - (m * p0[0])));
}