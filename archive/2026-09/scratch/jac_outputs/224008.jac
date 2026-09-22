"""Return seconds from midnight to the specified time."""
def time_from_midnight(update_time: str) -> int {
    update_hour = int(update_time[0:2]);
    update_minute = int(update_time[3:5]);
    return update_hour * 3600 + update_minute * 60;
}