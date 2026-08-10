"""Convert a time in seconds (google's transcript) to srt time format."""
def formatSrtTime(secTime: Any) -> object {
    (sec, micro) = str(secTime).split('.');
    (m, s) = divmod(int(sec), 60);
    (h, m) = divmod(m, 60);
    return "{:02}:{:02}:{:02},{}".format(h, m, s, micro);
}