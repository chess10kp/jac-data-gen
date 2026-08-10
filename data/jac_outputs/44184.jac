"""Returns True if bounds_inside fits entirely within bounds_around."""
def fits(bounds_inside: tuple[int, int, int, int], bounds_around: tuple[int, int, int, int]) -> bool {
    (x1_min, y1_min, x1_max, y1_max) = bounds_inside;
    (x2_min, y2_min, x2_max, y2_max) = bounds_around;
    return x1_min >= x2_min and x1_max <= x2_max and y1_min >= y2_min and y1_max <= y2_max;
}