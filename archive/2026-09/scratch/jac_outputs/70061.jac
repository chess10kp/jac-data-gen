"""Seconds to hours, minutes, seconds"""
def sec2hms(seconds: int) -> tuple[int, int, int] {
    hours = seconds // (60 ** 2);
    rem = seconds % (60 ** 2);
    minutes = rem // 60;
    seconds = rem % 60;
    return (int(hours), int(minutes), seconds);
}