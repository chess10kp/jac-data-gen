"""Takes the a filesize in bytes and returns a nicely formatted string. """
def sizeof_fmt(num: float) -> str | None {
    for x in ["bytes", "KB", "MB", "GB", "TB"] {
        if num < 1024.0 {
            return f"{num:3.1f} {x}";
        }
        num /= 1024.0;
    }
}