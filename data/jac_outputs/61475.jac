"""Convert bytes to MB.... GB... etc."""
def convert_bytes(num: float) -> str | None {
    for x in ["bytes", "KB", "MB", "GB", "TB"] {
        if num < 1024.0 {
            return "%3.1f %s" % (num, x);
        }
        num /= 1024.0;
    }
}