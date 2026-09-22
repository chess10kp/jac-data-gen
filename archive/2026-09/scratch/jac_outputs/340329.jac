"""
Given a window and a set of disjoint subintervals, return the
"holes", which are the intervals of the refWindow not covered by
the given subintervals.
"""
def holes(refWindow: tuple[int, int, int], intervals: list[tuple[int, int]]) -> list[tuple[int, int]] {
    (_, win_start, win_end) = refWindow;
    output = [];
    intervals = sorted(intervals);
    last_e = win_start;
    for (s, e) in intervals {
        if s > last_e {
            output.append((last_e, s));
        }
        last_e = e;
    }
    if last_e < win_end {
        output.append((last_e, win_end));
    }
    return output;
}