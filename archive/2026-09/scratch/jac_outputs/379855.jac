"""
Returns an N-D array where each row represents a separate segmentation of continuous data with no gaps
greater than the max gap.
"""
def segment_times(timeseries: list[float], max_gap: float) -> list[list[float]] {
    time_segments = [];
    is_contiguous = False;
    arr_n = -1;
    for (i, t) in enumerate(timeseries) {
        if not is_contiguous {
            time_segments.append([t]);
            arr_n += 1;
        } else {
            time_segments[arr_n].append(t);
        }
        if i + 1 < len(timeseries) {
            is_contiguous = timeseries[i + 1] - t < max_gap;
        }
    }
    return time_segments;
}