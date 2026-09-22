"""
    Given that source interval i is the first source interval that
    intersects target interval j, return the index of the first source
    interval that matches target interval j maximally, or `None` if
    there is no such source interval.

    A source interval is said to *match* a target interval iff the ratio
    of the duration of the intersection of the intervals to the minimum
    of their durations is at least `_DURATION_THRESHOLD`. A source
    interval matches a target interval *maximally* iff the ratio is the
    maximum of such ratios over all matching source intervals.
    """
def _find_best_source_match(
    source_intervals: Any,
    target_intervals: Any,
    i: Any,
    j: Any,
    intersection_threshold: Any
) -> object {
    (start_j, end_j) = target_intervals[j];
    dur_j = end_j - start_j;
    k = i;
    best_k = None;
    best_fraction = 0;
    source_interval_count = len(source_intervals);
    while (k != source_interval_count) {
        (start_k, end_k) = source_intervals[k];
        if (start_k >= end_j) {
            break;
        } else {
            dur_k = end_k - start_k;
            intersection_start = max(start_k, start_j);
            intersection_end = min(end_k, end_j);
            intersection_dur = intersection_end - intersection_start;
            min_dur = min(dur_k, dur_j);
            fraction = intersection_dur / min_dur;
            if ((fraction >= intersection_threshold) and (fraction > best_fraction)) {
                best_k = k;
                best_fraction = fraction;
            }
            k += 1;
        }
    }
    return best_k;
}