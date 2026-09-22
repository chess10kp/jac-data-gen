"""
Return whether or not two rectangles collide.

Arguments:

- ``x1`` -- The horizontal position of the first rectangle.
- ``y1`` -- The vertical position of the first rectangle.
- ``w1`` -- The width of the first rectangle.
- ``h1`` -- The height of the first rectangle.
- ``x2`` -- The horizontal position of the second rectangle.
- ``y2`` -- The vertical position of the second rectangle.
- ``w2`` -- The width of the second rectangle.
- ``h2`` -- The height of the second rectangle.
"""
def rectangles_collide(
    x1: int, y1: int, w1: int, h1: int, x2: int, y2: int, w2: int, h2: int
) -> bool {
    return x1 < x2 + w2 and x1 + w1 > x2 and y1 < y2 + h2 and y1 + h1 > y2;
}