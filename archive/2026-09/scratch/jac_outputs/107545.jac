"""Remove intervals that are fully contained in another.

    [(10, 100), (20, 50), (70, 120), (130, 200), (10, 50), (140, 210), (150, 200)]

    results:

    [(10, 100), (70, 120), (130, 200), (140, 210)]
    """
def RemoveIntervalsContained(intervals: list[tuple[int, int]]) -> list[tuple[int, int]] {
    if not intervals {
        return [];
    }
    new_intervals = [];
    intervals.sort();
    (last_from, last_to) = intervals[0];
    for (this_from, this_to) in intervals[1:] {
        if this_from <= last_from and this_to >= last_to {
            (last_from, last_to) = (this_from, this_to);
            continue;
        }
        if last_from <= this_from and last_to >= this_to {
            continue;
        }
        new_intervals.append((last_from, last_to));
        (last_from, last_to) = (this_from, this_to);
    }
    new_intervals.append((last_from, last_to));
    return new_intervals;
}