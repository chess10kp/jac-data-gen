"""Return left_x and width of overlapping x of two rects."""
def find_x_overlap(
    rect1: dict[str, int | float],
    rect2: dict[str, int | float]
) -> tuple[int | float, int | float] | None {
    r1left = rect1['left_x'];
    r1right = r1left + rect1['width'];
    r2left = rect2['left_x'];
    r2right = r2left + rect2['width'];
    highest_start_point = r1left if r1left >= r2left else r2left;
    lowest_end_point = r1right if r1right <= r2right else r2right;
    if highest_start_point < lowest_end_point {
        return (highest_start_point, lowest_end_point - highest_start_point);
    }
    return None;
}