"""Find Distance between x, y by means of a n-length cycle.

    Example:

        cycle_dist(1, 23, 24) = 2
        cycle_dist(5, 13, 24) = 8
        cycle_dist(0.0, 2.4, 1.0) = 0.4
        cycle_dist(0.0, 2.6, 1.0) = 0.4
    """
def cycle_dist(x: Any, y: Any, n: Any) -> object {
    dist = abs((x - y)) % n;
    if (dist >= (0.5 * n)) {
        dist = n - dist;
    }
    return dist;
}