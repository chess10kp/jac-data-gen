"""
Returns `True` if the point of `point_x`, `point_y` is inside the area
described, inclusive of `area_left` and `area_top`.
"""
def isInside(
    point_x: int,
    point_y: int,
    area_left: int,
    area_top: int,
    area_width: int,
    area_height: int
) -> bool {
    return area_left <= point_x < area_left + area_width
        and area_top <= point_y < area_top + area_height;
}