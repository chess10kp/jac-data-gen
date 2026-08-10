"""Format a number of bytes as a string."""
def format_bytes(size: int | float) -> str {
    names = ("B", "KB", "MB", "GB", "TB");
    mag = 0;
    while size > 1024 {
        mag += 1;
        size = size / 1024.0;
    }
    return "{} {}".format(round(size, 2), names[mag]);
}