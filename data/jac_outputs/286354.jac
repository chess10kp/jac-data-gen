"""Converts seconds into hours, minutes and seconds."""
def time_convert(sec: int) -> str {
    mins = sec // 60;
    sec = sec % 60;
    hours = mins // 60;
    mins = mins % 60;
    return "{0}:{1}:{2}".format(int(hours), int(mins), sec);
}