"""Convert milliseconds to human readable time strings"""
def msec2time(msec: int) -> str {
    if msec >= 0 {
        hours = int(msec / 3600000);
        remainder = msec % 3600000;
        minutes = int(remainder / 60000);
        remainder = remainder % 60000;
        secs = remainder / 1000;
        return "%02d:%02d:%05.2f" % (hours, minutes, secs);
    }
    return "NONE";
}