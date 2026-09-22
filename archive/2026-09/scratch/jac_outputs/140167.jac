"""Formats size, a number of bytes, in a human-readable way."""
def human_bytes(size: int | float) -> str {
    suffices = ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB', 'HB'];
    for suffix in suffices {
        if size < 1024 {
            return "%3.1f %s" % (size, suffix);
        }
        size /= 1024.0;
    }
    return "big";
}