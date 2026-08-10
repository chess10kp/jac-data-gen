"""
Find the pixel a given distance from the virtual agent location.
"""
def left(x_pos: int, distance: int) -> int {
    x_pos - distance + 1
}