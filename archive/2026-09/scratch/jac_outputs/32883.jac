"""
    Compute the Riemann sum for a given partition

    Inputs:
        - func: any single variable function
        - partition: list of the form [(left, right, midpoint)]

    Outputs:
        - a float
    """
def riemann_sum(func: Any, partition: Any) -> object {
    return sum((func(point) * (right - left)) for (left, right, point) in partition);
}