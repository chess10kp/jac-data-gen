"""Convert milliseconds to minutes and seconds."""
def convert_time(milliseconds: int) -> tuple[int, int] {
    minutes = milliseconds // 60;
    seconds = milliseconds % 60;
    return (minutes, seconds);
}