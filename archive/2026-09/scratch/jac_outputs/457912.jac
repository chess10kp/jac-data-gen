"""This gets the time in hours, mins and seconds."""
def spltime(tseconds: int) -> tuple[int, int, int] {
    hours = tseconds // 3600;
    minutes = int(tseconds / 60) % 60;
    seconds = tseconds % 60;
    return (hours, minutes, seconds);
}