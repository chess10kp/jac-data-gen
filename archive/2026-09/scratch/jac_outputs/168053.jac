"""Complement a list of intervals with intervals not in list."""
def complement(intervals: list[tuple[int, int]], first: int | None = None, last: int | None = None) -> list[tuple[int, int]] {
    if len(intervals) == 0 {
        if first is not None and last is not None {
            return [(first, last)];
        }
        return [];
    }
    new_intervals = [];
    intervals.sort();
    (last_from, last_to) = intervals[0];
    if first is not None and first < last_from {
        new_intervals.append((first, last_from));
    }
    for (this_from, this_to) in intervals {
        if this_from > last_to {
            new_intervals.append((last_to, this_from));
        }
        last_from = this_from;
        last_to = max(last_to, this_to);
    }
    if last and last > last_to {
        new_intervals.append((last_to, last));
    }
    return new_intervals;
}