"""Convert elapsed seconds to hh:mm:ss.mmm format."""
def deltatime_str(deltatime_seconds: float) -> str {
    time_int = int(deltatime_seconds);
    time_dec = int((deltatime_seconds - time_int) * 1000);
    times = (time_int // 3600, (time_int % 3600) // 60, time_int % 60, time_dec);
    return '%02d:%02d:%02d.%03d' % times;
}