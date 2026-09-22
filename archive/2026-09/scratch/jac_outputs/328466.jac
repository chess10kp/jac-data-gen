"""Returns the area of a triangle given its 3 vertices in
    cartesian coordinates.
    """
def triangleArea(ax: Any, ay: Any, bx: Any, `by: Any, cx: Any, cy: Any) -> object {
    return (abs(((ax * (`by - cy)) + (bx * (cy - ay)) + (cx * (ay - `by)))) / 2);
}