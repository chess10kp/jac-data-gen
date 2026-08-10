"""Get a safe string to use as a filename."""
def get_safe_filename(title: str) -> str {
    keep_chars = (' ', '.', '_');
    return "".join(
        c for c in title if c.isalnum() or c in keep_chars
    ).rstrip();
}