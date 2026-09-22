""" Shift the intervals by weight """
def _shift_interval_by(intervals: Any, weight: Any) -> object {
    return [[(x + weight), (y + weight)] for [x, y] in intervals];
}