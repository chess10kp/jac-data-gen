"""
    Finds the orientation of an ordered set of vertices(p, q, r).

    p: First vertex represented as a tuple.
    q: Second vertex represented as a tuple.
    r: Third vertex represented as a tuple.

    returns:
    0 : Collinear points
    1 : Clockwise points
    2 : Counterclockwise
    """
def orientation(p: tuple[int, int], q: tuple[int, int], r: tuple[int, int]) -> int {
    val = (q[1] - p[1]) * (r[0] - q[0]) - (q[0] - p[0]) * (r[1] - q[1]);
    if val == 0 {
        return 0;
    }
    if val > 0 {
        return 1;
    }
    return 2;
}