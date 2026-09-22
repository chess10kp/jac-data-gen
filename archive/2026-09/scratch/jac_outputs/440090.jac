"""
    Given a base bearing and a second bearing, return the offset in degrees.

    Positive offsets are clockwise/to the right, negative offsets are
    counter-clockwise/to the left.
    """
def angle_offset(base: float, angle: float) -> float {
    offset = angle - base;
    if offset <= -180 {
        return 360 + offset;
    }
    if offset > 180 {
        return offset - 360;
    }
    return offset;
}