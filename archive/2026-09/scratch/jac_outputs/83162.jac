"""Prepends magic data to a filename to support long paths (Windows-specific)."""
def _filename(filename: str) -> str {
    if len(filename) > 255 {
        return '\\\\?\\' + filename;
    }
    return filename;
}