"""Check if log match criteria for rotation"""
def need_to_rotate_log(
    min_size: int,
    max_size: int,
    max_time_interval: int,
    log_size: int,
    time_interval: int
) -> bool {
    return log_size >= max_size or (time_interval == max_time_interval and log_size >= min_size);
}