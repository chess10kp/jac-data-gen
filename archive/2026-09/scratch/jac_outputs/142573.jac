"""Format seconds as hours, minutes, and seconds."""
def timeFormat(time: int | float) -> str {
    time = int(time);
    seconds = time % 60;
    time = time // 60;
    minutes = time % 60;
    time = time // 60;
    hours = time % 60;
    return f"{hours}h {minutes}m {seconds}s";
}