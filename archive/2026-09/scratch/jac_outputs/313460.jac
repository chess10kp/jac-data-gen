"""Convert a float measuring time difference in seconds into a tuple of (hours, minutes, seconds)"""
def readable_time(time_difference: float) -> tuple[float, float, float] {
    hours = time_difference // 3600;
    minutes = (time_difference // 60) % 60;
    seconds = time_difference % 60;
    return (hours, minutes, seconds);
}