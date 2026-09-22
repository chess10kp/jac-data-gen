"""Return bytes used at given time."""
def get_bytes_used(current_time: int, process_durations: list[int]) -> int {
    bytes_used = 0;
    for p_time in process_durations {
        if p_time > current_time {
            break;
        }
        bytes_used += current_time // p_time;
    }
    return bytes_used;
}