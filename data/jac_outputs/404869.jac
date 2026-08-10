"""Get the thumbnail URL for the given size."""
def thumbnail(value: str, size: str) -> str {
    return value.replace('.jpg', '.' + size + '.jpg');
}