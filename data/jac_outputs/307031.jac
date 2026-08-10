"""Extract sorted start and end timestamps for segments matching a sensor."""
def get_time_segments(sensor: int, segments: list[tuple[int, tuple[int, int, int]]]) -> tuple[list[int], list[int]] {
    starts = [];
    ends = [];
    for (_, segment) in segments {
        if segment[0] == sensor {
            starts.append(segment[1]);
            ends.append(segment[2]);
        }
    }
    starts_sorted = [start for (start, _) in sorted(zip(starts, ends))];
    ends_sorted = [end for (_, end) in sorted(zip(starts, ends))];
    return (starts_sorted, ends_sorted);
}