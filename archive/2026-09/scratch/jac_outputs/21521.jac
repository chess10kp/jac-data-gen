"""time_delta -> 1:01:40"""
def duration_hms(time_delta: Any) -> object {
    (minutes, s) = divmod(time_delta, 60);
    (h, minutes) = divmod(minutes, 60);
    return ("%d:%02d:%02d" % (h, minutes, s));
}