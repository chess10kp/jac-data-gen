"""Convert bytes to human-readable KB, MB, GB, etc."""
def convert_bytes(num: int | float) -> str | None {
    if num < 1024.0 {
        return "%3.0f bytes" % num;
    }
    num /= 1024.0;
    for x in ['KB', 'MB', 'GB', 'TB'] {
        if num < 1024.0 {
            return "%3.1f %s" % (num, x);
        }
        num /= 1024.0;
    }
}