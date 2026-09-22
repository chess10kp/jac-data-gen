"""Given start time, end time and interval for reading data, determines limits to use."""
def _get_read_limits(start: int, end: int, interval: int, info: dict[str, int]) -> tuple[int, int] {
    start *= info['samp_freq'];
    end *= info['samp_freq'];
    if start < 0 {
        start = 0;
    }
    if end < 0 {
        end = info['samp_count'];
    }
    if end < start {
        (start, end) = (end, start);
    }
    interval_end = start + interval * info['samp_freq'];
    if interval_end < start {
        interval_end = info['samp_count'];
    }
    end = min(end, interval_end, info['samp_count']);
    return (int(start), int(end));
}