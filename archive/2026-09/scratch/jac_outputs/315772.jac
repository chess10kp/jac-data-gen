"""Checks whether these points lie within the window of interest.

Points is a list of one start, one end coordinate (ints)
"""
def points_in_window(points: list[int | None]) -> bool {
    if None in points or points[0] < -5 or points[1] < -5 or points[0] > 5 or points[1] > 5 {
        return False;
    }
    return True;
}